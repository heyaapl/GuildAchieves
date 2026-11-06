-- Author      : heyaapl
-- Create Date : 12/28/2024
-- Guild Achieves - Automatically congratulates guildies on achievements with humorous messages!

GuildAchieves = LibStub("AceAddon-3.0"):NewAddon("GuildAchieves", "AceConsole-3.0")

-- GLOBALS: GuildAchieves, GuildAchievesData

-- Private event frame - intentionally UNNAMED to avoid global frame taint on Midnight 12.0+
-- Previously we used AceEvent-3.0's shared "AceEvent30Frame" which other addons also use; when
-- any addon tainted that shared frame, Midnight's stricter taint rules threw:
--   ADDON FORBIDDEN: AceEvent30Frame:RegisterEvent()
-- An unnamed private frame is NOT shared across addons and cannot be tainted externally.
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	local handler = GuildAchieves and GuildAchieves[event]
	if handler then
		-- Call the method on the addon object, matching AceEvent's dispatch signature
		handler(GuildAchieves, event, ...)
	end
end)

-- Local references
local db
local defaults
local optionsCategoryID  -- Settings category ID returned by AddToBlizOptions (numeric on 12.0+ clients)

-- Cooldown tracking to prevent spam
local lastMessageTime = 0
local MESSAGE_COOLDOWN = 5 -- seconds between messages

-- Client Version Detection
-- Used to pick version-specific messages and behaviors
local isBCC = false          -- Burning Crusade Classic (no achievements system)
local isForever = false      -- WoW: Forever (WOW_PROJECT_CAMELOT) - Vanilla content on the modern client, no achievements
local isMidnight = false     -- WoW Midnight (12.0.x) - retail
local isRetail = false       -- Retail (any modern version)
local tocVersion = 0
do
	local _, _, _, toc = GetBuildInfo()
	tocVersion = toc or 0
	-- WoW: Forever identifies itself via WOW_PROJECT_CAMELOT (TOC 16001). Check the project ID
	-- rather than the TOC range so a future TOC bump on Forever doesn't break detection.
	isForever = (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
	isBCC = (tocVersion >= 20000 and tocVersion < 30000)
	isMidnight = (tocVersion >= 120000 and tocVersion < 130000)
	-- Retail includes TWW (11.x), Midnight (12.x), and beyond
	isRetail = (tocVersion >= 100000) and not isForever
end

-- Flavors without an achievement system fall back to congratulating milestone level-ups
-- detected by polling the guild roster (see the Level-Up Polling System below).
local useLevelTracking = isBCC or isForever

-- Level-Up Tracking System (session-only, no persistence)
-- Only tracks online guild members while the addon player is online
-- Clears tracked levels when players go offline to avoid tracking offline progress
local bccTracker = {
	onlineLevels = {},     -- [playerName] = level (only currently-online players)
	ticker = nil,          -- C_Timer ticker for polling
	POLL_INTERVAL = 30,    -- seconds between roster polls
}

-- Milestone levels that trigger congratulations, per flavor
local BCC_MILESTONES = {
	[10] = true, [20] = true, [30] = true, [40] = true,
	[50] = true, [58] = true, [60] = true, [70] = true,
}
-- WoW: Forever is Vanilla content with a level 60 cap (mount at 40, epic mount at 60)
local FOREVER_MILESTONES = {
	[10] = true, [20] = true, [30] = true, [40] = true,
	[50] = true, [60] = true,
}
local LEVEL_MILESTONES = isForever and FOREVER_MILESTONES or BCC_MILESTONES

-- Achievement batching system
-- Collects achievements over a window to handle multiple achievements at once
local BATCH_WINDOW = 3 -- seconds to collect achievements before sending
local achievementBatch = {
	isCollecting = false,
	startTime = 0,
	-- playerAchievements[playerName] = { {achievementID, achievementName, category, level}, ... }
	playerAchievements = {},
	-- achievementPlayers[achievementID] = { playerName1, playerName2, ... }
	achievementPlayers = {},
	-- achievementInfo[achievementID] = { name = "...", category = "...", level = nil }
	achievementInfo = {},
}

-- Debug system
local function DebugPrint(...)
	if GuildAchieves and GuildAchieves.db and GuildAchieves.db.profile and GuildAchieves.db.profile.DebugMode then
		GuildAchieves:Print("[DEBUG]", ...)
	end
end

-- =============================================================================
-- Guild chat sending
--
-- The global SendChatMessage was deprecated in 11.2 in favor of C_ChatInfo.SendChatMessage, so
-- we prefer that and fall back to the global on older clients.
--
-- WoW: Forever (and possibly later retail builds) only lets addons post to guild chat from a
-- hardware event: a send from a C_Timer callback returns normally but the client drops it with
-- "Interface action failed because of an AddOn" (ADDON_ACTION_BLOCKED). Since every message we
-- send comes out of a timer or a roster poll, on those clients we queue messages and flush the
-- queue from the next thing the player does: a key press, a click in the game world, a jump, or
-- sending a chat line. Keyboard capture propagates the key, and we never swallow mouse clicks.
-- =============================================================================

local lastDirectSend = nil      -- { message = ..., time = ... } for the most recent direct send
local function SendGuildChatNow(message)
	if not message or message == "" then return false end

	local inLockdown = false
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
		local ok, result = pcall(C_ChatInfo.InChatMessagingLockdown)
		inLockdown = ok and result == true
	end

	local api, fn
	if C_ChatInfo and C_ChatInfo.SendChatMessage then
		api, fn = "C_ChatInfo.SendChatMessage", C_ChatInfo.SendChatMessage
	elseif SendChatMessage then
		api, fn = "SendChatMessage", SendChatMessage
	else
		DebugPrint("No chat send API available on this client!")
		return false
	end

	lastDirectSend = { message = message, time = GetTime() }
	local ok, err = pcall(fn, message, "GUILD")
	if ok then
		DebugPrint("Sent via", api, (inLockdown and "(client reports chat lockdown!)" or ""), "->", message)
	else
		DebugPrint("Error from", api, ":", tostring(err), (inLockdown and "(client reports chat lockdown)" or ""))
	end
	return ok
end

-- Hardware-event queue
local chatQueue = {}                        -- { { message = ..., queuedAt = ... }, ... }
local CHAT_QUEUE_MAX_AGE = 180              -- seconds; a congrats older than this is dropped, not posted late
local requiresHardwareEvent = isForever     -- known for Forever; learned at runtime elsewhere (see ADDON_ACTION_BLOCKED)
local hardwareWatcher                       -- keyboard-capturing frame, only shown while something is queued

local function UpdateHardwareWatcher()
	if not hardwareWatcher then return end
	if #chatQueue > 0 and not InCombatLockdown() then
		hardwareWatcher:Show()
	else
		hardwareWatcher:Hide()
	end
end

-- Called from hardware-event handlers only. Sends everything queued, in order.
local function FlushChatQueue()
	if #chatQueue == 0 then return end
	local pending = chatQueue
	chatQueue = {}
	local now = GetTime()
	for _, entry in ipairs(pending) do
		if now - entry.queuedAt <= CHAT_QUEUE_MAX_AGE then
			SendGuildChatNow(entry.message)
		else
			DebugPrint("Dropped a queued message that waited too long for a hardware event:", entry.message)
		end
	end
	UpdateHardwareWatcher()
end

local function QueueGuildChat(message)
	table.insert(chatQueue, { message = message, queuedAt = GetTime() })
	DebugPrint("Queued for the next key press / click (", #chatQueue, "waiting ):", message)
	UpdateHardwareWatcher()
end

-- Public entry point used by every message path in the addon
local function SendGuildChat(message)
	if not message or message == "" then return false end
	if requiresHardwareEvent then
		QueueGuildChat(message)
		return true
	end
	return SendGuildChatNow(message)
end

-- If a direct send gets blocked, remember that this client needs a hardware event and re-queue
-- the message so it still goes out on the player's next input. Wired to ADDON_ACTION_BLOCKED.
local function OnAddonActionBlocked(addonName, functionName)
	if addonName ~= "GuildAchieves" then return end
	if not functionName or not tostring(functionName):find("SendChatMessage") then return end
	if not lastDirectSend or GetTime() - lastDirectSend.time > 2 then return end
	if not requiresHardwareEvent then
		requiresHardwareEvent = true
		DebugPrint("Client blocked a timer-driven guild message; switching to hardware-event queue for this session")
	end
	QueueGuildChat(lastDirectSend.message)
	lastDirectSend = nil
end

do
	-- Keyboard: a tiny frame with keyboard enabled and propagation on sees every key press while
	-- shown and passes it along untouched. SetPropagateKeyboardInput is protected in combat, so
	-- it is set exactly once here at load; afterwards we only Show/Hide (and never in combat).
	hardwareWatcher = CreateFrame("Frame", nil, UIParent)
	hardwareWatcher:SetFrameStrata("TOOLTIP")
	hardwareWatcher:SetFrameLevel(10000)
	hardwareWatcher:SetSize(1, 1)
	hardwareWatcher:SetPoint("TOPLEFT")
	hardwareWatcher:EnableMouse(false)
	hardwareWatcher:EnableKeyboard(true)
	if hardwareWatcher.SetPropagateKeyboardInput then
		hardwareWatcher:SetPropagateKeyboardInput(true)
	end
	hardwareWatcher:SetScript("OnKeyDown", function() FlushChatQueue() end)
	hardwareWatcher:Hide()

	-- Mouse: clicks on the game world (camera turns, movement, targeting) are hardware events.
	-- HookScript leaves the original handler untouched, so nothing is swallowed.
	if WorldFrame and WorldFrame.HookScript then
		WorldFrame:HookScript("OnMouseDown", function() FlushChatQueue() end)
	end
	-- Jumping and sending a chat line are hardware events too (the chat edit box has keyboard
	-- focus while typing, so the watcher frame doesn't see that Enter key).
	if hooksecurefunc then
		if JumpOrAscendStart then hooksecurefunc("JumpOrAscendStart", function() FlushChatQueue() end) end
		if ChatEdit_SendText then hooksecurefunc("ChatEdit_SendText", function() FlushChatQueue() end) end
	end
end

-- Event handlers (dispatched by the private eventFrame at the top of the file)
function GuildAchieves:ADDON_ACTION_BLOCKED(event, addonName, functionName)
	OnAddonActionBlocked(addonName, functionName)
end
function GuildAchieves:PLAYER_REGEN_DISABLED()
	-- Entering combat: hide the keyboard watcher (nothing protected is touched by Hide)
	UpdateHardwareWatcher()
end
function GuildAchieves:PLAYER_REGEN_ENABLED()
	-- Leaving combat: show it again if anything is still waiting
	UpdateHardwareWatcher()
end

-- ElvUI-Style UI System (independent implementation)
local GuildAchievesUI = {
	-- Template-specific Color Schemes
	templates = {
		Default = {
			backdrop = {0, 0, 0, 1},           -- Solid black background
			backdropFade = {0, 0, 0, 1},       -- Solid black
			border = {1, 0.82, 0, 1},          -- Gold border
			text = {1, 0.82, 0, 1},            -- Gold text
			textHover = {1, 1, 1, 1},          -- White hover
			scrollbar = {1, 0.82, 0, 1},       -- Gold scrollbar
			alpha = 1.0,                       -- Fully opaque
		},
		Transparent = {
			backdrop = {0.1, 0.1, 0.1, 1},     -- Dark gray background
			backdropFade = {0.06, 0.06, 0.06, 1},
			border = {0, 0, 0, 1},             -- Black border
			text = {1, 1, 1, 1},               -- White text
			textHover = {0.7, 0.7, 0.7, 1},    -- Light gray hover
			scrollbar = {1, 1, 1, 1},          -- White scrollbar
			alpha = 0.7,                       -- 70% opacity
		},
		ClassColor = {
			backdrop = {0.1, 0.1, 0.1, 1},
			backdropFade = {0.06, 0.06, 0.06, 1},
			border = nil,                       -- Will be set to class color
			text = nil,                         -- Will be set to class color
			textHover = {1, 1, 1, 1},          -- White hover
			scrollbar = nil,                    -- Will be set to class color
			alpha = 0.8,                       -- 80% opacity
		}
	},
	
	-- Current active template colors
	colors = {
		backdrop = {0, 0, 0, 1},
		backdropFade = {0, 0, 0, 1},
		border = {0, 0, 0, 1},
		text = {1, 0.82, 0, 1},
		textHover = {1, 1, 1, 1},
		scrollbar = {1, 0.82, 0, 1},
		classColor = nil,
		alpha = 1.0
	}
}

-- Initialize class color and template colors
local function InitializeClassColor()
	local _, class = UnitClass("player")
	if class and RAID_CLASS_COLORS[class] then
		local color = RAID_CLASS_COLORS[class]
		GuildAchievesUI.colors.classColor = {color.r, color.g, color.b, 1}
		
		GuildAchievesUI.templates.ClassColor.border = {color.r, color.g, color.b, 1}
		GuildAchievesUI.templates.ClassColor.text = {color.r, color.g, color.b, 1}
		GuildAchievesUI.templates.ClassColor.scrollbar = {color.r, color.g, color.b, 1}
		
		if class == "PRIEST" then
			GuildAchievesUI.templates.ClassColor.textHover = {0.7, 0.7, 0.7, 1}
		end
	else
		GuildAchievesUI.colors.classColor = {0, 0, 0, 1}
		GuildAchievesUI.templates.ClassColor.border = {0, 0, 0, 1}
		GuildAchievesUI.templates.ClassColor.text = {1, 1, 1, 1}
		GuildAchievesUI.templates.ClassColor.scrollbar = {0, 0, 0, 1}
	end
end

-- Update active colors based on template selection
local function UpdateTemplateColors(template)
	template = template or "Default"
	local templateColors = GuildAchievesUI.templates[template]
	if not templateColors then
		templateColors = GuildAchievesUI.templates.Default
	end
	
	GuildAchievesUI.colors.backdrop = templateColors.backdrop
	GuildAchievesUI.colors.backdropFade = templateColors.backdropFade  
	GuildAchievesUI.colors.border = templateColors.border
	GuildAchievesUI.colors.text = templateColors.text
	GuildAchievesUI.colors.textHover = templateColors.textHover
	GuildAchievesUI.colors.scrollbar = templateColors.scrollbar
	GuildAchievesUI.colors.alpha = templateColors.alpha
end

-- Achievement Category Detection
-- Maps achievement category IDs to our message categories
local ACHIEVEMENT_CATEGORIES = {
	-- Level achievements (Character > Level)
	[81] = "Level",           -- Level category
	
	-- Quest achievements
	[96] = "Quests",          -- Quests category
	[14861] = "Quests",       -- Pandaria quests
	[97] = "Quests",          -- Eastern Kingdoms
	[95] = "Quests",          -- Kalimdor
	[14862] = "Quests",       -- Cataclysm quests
	
	-- Exploration
	[97] = "Exploration",     -- Eastern Kingdoms exploration
	[14777] = "Exploration",  -- Exploration category
	[14778] = "Exploration",  -- Pandaria exploration
	
	-- Dungeons & Raids
	[168] = "Dungeons",       -- Dungeons & Raids
	[14808] = "Dungeons",     -- Pandaria Dungeons
	[15067] = "Dungeons",     -- Scenarios
	[14922] = "Raids",        -- Pandaria Raids
	[15093] = "Raids",        -- Throne of Thunder
	[15113] = "Raids",        -- Siege of Orgrimmar
	
	-- PvP
	[95] = "PvP",             -- General PvP
	[14901] = "PvP",          -- Pandaria PvP
	[165] = "PvP",            -- Arena
	[14881] = "PvP",          -- Rated Battlegrounds
	
	-- Professions
	[169] = "Professions",    -- Professions category
	[170] = "Professions",    -- Cooking
	[171] = "Professions",    -- Fishing
	[172] = "Professions",    -- First Aid
	
	-- Reputation
	[201] = "Reputation",     -- Reputation category
	[14864] = "Reputation",   -- Pandaria factions
	
	-- Pet Battles
	[15117] = "PetBattles",   -- Pet Battles
	[15119] = "PetBattles",   -- Collect
	[15118] = "PetBattles",   -- Battle
	
	-- World Events
	[155] = "WorldEvents",    -- World Events
	[156] = "WorldEvents",    -- Lunar Festival
	[157] = "WorldEvents",    -- Love is in the Air
	[158] = "WorldEvents",    -- Noblegarden
	[159] = "WorldEvents",    -- Children's Week
	[160] = "WorldEvents",    -- Midsummer
	[161] = "WorldEvents",    -- Brewfest
	[162] = "WorldEvents",    -- Hallow's End
	[163] = "WorldEvents",    -- Pilgrim's Bounty
	[164] = "WorldEvents",    -- Winter Veil

	-- =========================================================================
	-- MIDNIGHT (12.0.1) Categories - retail WoW
	-- Category IDs sourced from Wowhead PTR data and may shift slightly on launch;
	-- the GetAchievementCategory API returns these dynamically so our fallback
	-- keyword detection (in GetAchievementCategoryInfo) also catches them.
	-- =========================================================================
	-- Midnight expansion top-level
	[15552] = "MidnightRaids",       -- Midnight Raids (placeholder, actual ID varies)
	[15553] = "MidnightKeystones",   -- Midnight Mythic+ / Keystones
	[15554] = "MidnightDelves",      -- Midnight Delves
	[15555] = "MidnightExploration", -- Midnight Exploration
	[15556] = "MidnightPrey",        -- Prey system
	[15557] = "MidnightHousing",     -- Housing (new system in Midnight)
	[15558] = "MidnightClass",       -- Class achievements
	[15559] = "MidnightHaranir",     -- Haranir allied race
	-- Categories that also appear in retail generally; we map them for coverage
	[15303] = "Dungeons",            -- Retail Dungeons & Raids container (TWW-era)
	[15522] = "Dungeons",            -- Retail Dungeons (may update in 12.x)
	[15301] = "Raids",               -- Retail Raids container
}

-- Level achievement IDs mapping
local LEVEL_ACHIEVEMENT_IDS = {
	[6] = 10,      -- Level 10
	[7] = 20,      -- Level 20
	[8] = 30,      -- Level 30
	[9] = 40,      -- Level 40
	[10] = 50,     -- Level 50
	[11] = 60,     -- Level 60
	[12] = 70,     -- Level 70
	[13] = 80,     -- Level 80
	[4826] = 85,   -- Level 85
	[6193] = 90,   -- Level 90
}

-- Safe wrapper around GetAchievementInfo - API signature has varied over expansions
-- Returns just the achievement name (or nil) without risking a runtime error
local function SafeGetAchievementName(achievementID)
	if not GetAchievementInfo then return nil end
	local ok, _, name = pcall(GetAchievementInfo, achievementID)
	if ok and name then return name end
	return nil
end

-- Safe wrapper around GetAchievementCategory - returns categoryID or nil
local function SafeGetAchievementCategory(achievementID)
	if not GetAchievementCategory then return nil end
	local ok, categoryID = pcall(GetAchievementCategory, achievementID)
	if ok then return categoryID end
	return nil
end

-- Safe wrapper around GetCategoryInfo - returns (name, parentID) or (nil, nil)
-- In Midnight/retail this may be relocated to C_AchievementInfo; handle both
local function SafeGetCategoryInfo(categoryID)
	local fn = GetCategoryInfo
	if C_AchievementInfo and C_AchievementInfo.GetCategoryInfo then
		fn = C_AchievementInfo.GetCategoryInfo
	end
	if not fn then return nil, nil end
	local ok, name, parentID = pcall(fn, categoryID)
	if ok then return name, parentID end
	return nil, nil
end

-- Get category from achievement ID
local function GetAchievementCategoryInfo(achievementID)
	-- Check if it's a level achievement first
	if LEVEL_ACHIEVEMENT_IDS[achievementID] then
		return "Level", LEVEL_ACHIEVEMENT_IDS[achievementID]
	end

	local name = SafeGetAchievementName(achievementID)

	local categoryID = SafeGetAchievementCategory(achievementID)
	if categoryID and ACHIEVEMENT_CATEGORIES[categoryID] then
		return ACHIEVEMENT_CATEGORIES[categoryID], nil
	end

	-- Try parent category
	if categoryID then
		local _, parentID = SafeGetCategoryInfo(categoryID)
		if parentID and ACHIEVEMENT_CATEGORIES[parentID] then
			return ACHIEVEMENT_CATEGORIES[parentID], nil
		end
	end

	-- Check achievement name for keywords
	if name then
		local lowerName = name:lower()

		-- Level detection by name
		if lowerName:match("level %d+") then
			local level = tonumber(lowerName:match("level (%d+)"))
			if level then
				return "Level", level
			end
		end

		-- Midnight-specific keyword detection (check BEFORE generic categories)
		-- Uses zone, system, and lore names from Midnight 12.0.1
		if lowerName:match("midnight") or lowerName:match("voidstorm") or
		   lowerName:match("quel'danas") or lowerName:match("quel'thalas") or
		   lowerName:match("voidspire") or lowerName:match("dreamrift") or
		   lowerName:match("belo'ren") or lowerName:match("l'ura") then
			if lowerName:match("keystone") or lowerName:match("mythic") then
				return "MidnightKeystones", nil
			end
			if lowerName:match("raid") or lowerName:match("boss") or lowerName:match("voidspire") or lowerName:match("dreamrift") then
				return "MidnightRaids", nil
			end
			if lowerName:match("explor") or lowerName:match("harandar") or lowerName:match("zul'aman") or lowerName:match("eversong") then
				return "MidnightExploration", nil
			end
		end
		if lowerName:match("delve") then return "MidnightDelves", nil end
		if lowerName:match("prey") or lowerName:match("preyseeker") then return "MidnightPrey", nil end
		if lowerName:match("housing") or lowerName:match("decorator") or lowerName:match("decoration") or lowerName:match("home") then return "MidnightHousing", nil end
		if lowerName:match("haranir") or lowerName:match("hara'ti") then return "MidnightHaranir", nil end
		if lowerName:match("devourer") then return "MidnightClass", nil end

		-- Generic category detection by keywords
		if lowerName:match("explor") then return "Exploration", nil end
		if lowerName:match("dungeon") or lowerName:match("heroic") then return "Dungeons", nil end
		if lowerName:match("raid") or lowerName:match("boss") then return "Raids", nil end
		if lowerName:match("arena") or lowerName:match("battleground") or lowerName:match("honorable") then return "PvP", nil end
		if lowerName:match("craft") or lowerName:match("skill") or lowerName:match("profession") then return "Professions", nil end
		if lowerName:match("reputation") or lowerName:match("exalted") or lowerName:match("renown") then return "Reputation", nil end
		if lowerName:match("pet") or lowerName:match("battle pet") then return "PetBattles", nil end
		if lowerName:match("scenario") then return "Scenarios", nil end
		if lowerName:match("quest") or lowerName:match("loremaster") then return "Quests", nil end
		if lowerName:match("festival") or lowerName:match("holiday") or lowerName:match("brewfest") or lowerName:match("noblegarden") then return "WorldEvents", nil end
	end

	-- Default fallback
	return "General", nil
end

-- Get a random message for an achievement
local function GetRandomMessage(category, level, playerName, achievementName)
	if not GuildAchievesData then
		DebugPrint("GuildAchievesData not loaded!")
		return nil
	end

	local messages

	-- For level achievements, prefer Midnight-specific messages when on Midnight client + level 90
	if category == "Level" and level then
		if isMidnight and level == 90 and GuildAchievesData.MidnightLevel90Messages then
			messages = GuildAchievesData.MidnightLevel90Messages
		elseif GuildAchievesData.Levels and GuildAchievesData.Levels[level] then
			messages = GuildAchievesData.Levels[level]
		end
	end

	-- Midnight-specific categories have their own message pool
	if (not messages or #messages == 0) and category and category:match("^Midnight") then
		if GuildAchievesData.MidnightCategories and GuildAchievesData.MidnightCategories[category] then
			messages = GuildAchievesData.MidnightCategories[category]
		end
	end

	-- Fall back to category messages
	if not messages or #messages == 0 then
		if GuildAchievesData.Categories and GuildAchievesData.Categories[category] then
			messages = GuildAchievesData.Categories[category]
		end
	end

	-- If still nothing and it's a Midnight raid/dungeon/etc., fall back to the generic equivalent
	if not messages or #messages == 0 then
		local fallback = nil
		if category == "MidnightRaids" then fallback = "Raids"
		elseif category == "MidnightKeystones" or category == "MidnightDelves" then fallback = "Dungeons"
		elseif category == "MidnightExploration" then fallback = "Exploration"
		elseif category == "MidnightClass" or category == "MidnightPrey" or category == "MidnightHousing" or category == "MidnightHaranir" then fallback = "General"
		end
		if fallback and GuildAchievesData.Categories and GuildAchievesData.Categories[fallback] then
			messages = GuildAchievesData.Categories[fallback]
		end
	end
	
	-- Fall back to general
	if not messages or #messages == 0 then
		if GuildAchievesData.Categories and GuildAchievesData.Categories["General"] then
			messages = GuildAchievesData.Categories["General"]
		end
	end
	
	if not messages or #messages == 0 then
		DebugPrint("No messages found for category:", category)
		return nil
	end
	
	-- Pick a random message
	local message = messages[math.random(#messages)]
	
	-- Replace placeholders
	message = message:gsub("{player}", playerName)
	message = message:gsub("{achievement}", achievementName or "an achievement")
	if level then
		message = message:gsub("{level}", tostring(level))
	end
	
	return message
end

-- Fill the placeholders shared by all level-up message pools
local function FillLevelPlaceholders(message, playerName, level, className)
	message = message:gsub("{player}", playerName)
	message = message:gsub("{level}", tostring(level))
	message = message:gsub("{class}", className or "adventurer")
	return message
end

-- Get a BCC milestone level-up message
local function GetBCCLevelMessage(level, playerName)
	if not GuildAchievesData or not GuildAchievesData.BCCLevels then
		DebugPrint("BCCLevels data not loaded!")
		return nil
	end

	local messages = GuildAchievesData.BCCLevels[level]
	if not messages or #messages == 0 then
		-- Fall back to generic BCC milestone messages
		messages = GuildAchievesData.BCCLevels["Generic"]
		if not messages or #messages == 0 then
			DebugPrint("No BCC messages found for level:", level)
			return nil
		end
	end

	return FillLevelPlaceholders(messages[math.random(#messages)], playerName, level)
end

-- Pick one message from a list of { pool = {...}, weight = n } candidates
local function PickWeightedMessage(candidates)
	local total = 0
	for _, c in ipairs(candidates) do total = total + c.weight end
	if total <= 0 then return nil end
	local roll = math.random() * total
	for _, c in ipairs(candidates) do
		roll = roll - c.weight
		if roll <= 0 then return c.pool[math.random(#c.pool)] end
	end
	local last = candidates[#candidates].pool
	return last[math.random(#last)]
end

-- Get a WoW: Forever level-up message. Every level dings on Forever, so the pools are mixed:
-- milestone levels (10/20/.../60) lean on their own messages, everything else draws from the
-- player's class pool, the level-range pool for the zones they're in, and the generic pool.
local function GetForeverLevelMessage(level, playerName, classToken, className)
	local data = GuildAchievesData
	if not data or not data.ForeverLevels then
		DebugPrint("ForeverLevels data not loaded!")
		return nil
	end

	local candidates = {}
	local function add(pool, weight)
		if pool and #pool > 0 then table.insert(candidates, { pool = pool, weight = weight }) end
	end

	local milestonePool = data.ForeverLevels[level]
	local classPool = classToken and data.ForeverClassLevels and data.ForeverClassLevels[classToken]
	local rangePool
	if data.ForeverLevelRanges then
		for _, range in ipairs(data.ForeverLevelRanges) do
			if level >= range.min and level <= range.max then
				rangePool = range.messages
				break
			end
		end
	end

	if milestonePool then
		add(milestonePool, 60)
		add(classPool, 25)
		add(rangePool, 10)
		add(data.ForeverLevels["Generic"], 5)
	else
		add(classPool, 45)
		add(rangePool, 30)
		add(data.ForeverLevels["Generic"], 25)
	end

	local message = PickWeightedMessage(candidates)
	if not message then
		DebugPrint("No Forever messages found for level:", level)
		return nil
	end
	return FillLevelPlaceholders(message, playerName, level, className)
end

-- Dispatch to the right flavor's level-up pool
local function GetLevelUpMessage(ding)
	if isForever then
		return GetForeverLevelMessage(ding.level, ding.name, ding.class, ding.className)
	end
	return GetBCCLevelMessage(ding.level, ding.name)
end

-- Format a list of names nicely (e.g., "Alice, Bob, and Charlie")
local function FormatNameList(names)
	local count = #names
	if count == 0 then return "" end
	if count == 1 then return names[1] end
	if count == 2 then return names[1] .. " and " .. names[2] end
	
	-- For 3+ names
	local result = ""
	for i = 1, count - 1 do
		result = result .. names[i] .. ", "
	end
	result = result .. "and " .. names[count]
	return result
end

-- One combined message when a single roster poll finds many level-ups at once (WoW: Forever only,
-- since every level dings there). Keeps a busy leveling night from flooding guild chat.
local MULTI_DING_THRESHOLD = 3
local function GetForeverMultiDingMessage(dings)
	local entries = {}
	for _, ding in ipairs(dings) do
		table.insert(entries, ding.name .. " (" .. tostring(ding.level) .. ")")
	end
	local list = FormatNameList(entries)
	local pool = GuildAchievesData and GuildAchievesData.ForeverMultiDing
	if not pool or #pool == 0 then
		return "Grats to " .. list .. " on the dings!"
	end
	local message = pool[math.random(#pool)]
	message = message:gsub("{list}", list)
	message = message:gsub("{count}", tostring(#dings))
	return message
end

-- Get combo message for one player earning multiple achievements
local function GetMultiAchievementMessage(playerName, achievements)
	if not GuildAchievesData or not GuildAchievesData.Combos or not GuildAchievesData.Combos.MultiAchievement then
		-- Fallback if combo messages not loaded
		local achieveNames = {}
		for _, achieve in ipairs(achievements) do
			table.insert(achieveNames, achieve.name)
		end
		return playerName .. " just earned " .. #achievements .. " achievements: " .. table.concat(achieveNames, ", ") .. "! Overachiever!"
	end
	
	local messages = GuildAchievesData.Combos.MultiAchievement
	local message = messages[math.random(#messages)]
	
	-- Build achievement list and categories
	local achieveNames = {}
	local categories = {}
	local hasLevel = false
	local levelNum = nil
	
	for _, achieve in ipairs(achievements) do
		table.insert(achieveNames, achieve.name)
		if achieve.category == "Level" then
			hasLevel = true
			levelNum = achieve.level
		end
		categories[achieve.category] = true
	end
	
	-- Count unique categories
	local categoryCount = 0
	local categoryList = {}
	for cat, _ in pairs(categories) do
		categoryCount = categoryCount + 1
		table.insert(categoryList, cat)
	end
	
	-- Replace placeholders
	message = message:gsub("{player}", playerName)
	message = message:gsub("{count}", tostring(#achievements))
	message = message:gsub("{achievements}", FormatNameList(achieveNames))
	message = message:gsub("{categories}", FormatNameList(categoryList))
	message = message:gsub("{categoryCount}", tostring(categoryCount))
	if levelNum then
		message = message:gsub("{level}", tostring(levelNum))
	end
	
	return message
end

-- Get group celebration message for multiple players earning the same achievement
local function GetGroupAchievementMessage(achievementName, achievementCategory, players)
	if not GuildAchievesData or not GuildAchievesData.Combos then
		-- Fallback
		return "Grats " .. FormatNameList(players) .. " on " .. achievementName .. "!"
	end
	
	local messages
	local playerCount = #players
	
	-- Pick appropriate message pool based on group size
	if playerCount >= 20 and GuildAchievesData.Combos.LargeRaid then
		messages = GuildAchievesData.Combos.LargeRaid
	elseif playerCount >= 10 and GuildAchievesData.Combos.Raid then
		messages = GuildAchievesData.Combos.Raid
	elseif playerCount >= 5 and GuildAchievesData.Combos.Party then
		messages = GuildAchievesData.Combos.Party
	elseif GuildAchievesData.Combos.SmallGroup then
		messages = GuildAchievesData.Combos.SmallGroup
	else
		return "Grats " .. FormatNameList(players) .. " on " .. achievementName .. "!"
	end
	
	local message = messages[math.random(#messages)]
	
	-- For large groups, we might not list all names (chat limit)
	local displayNames
	if playerCount > 5 then
		-- Show first few names + count
		displayNames = players[1] .. ", " .. players[2] .. ", " .. players[3] .. ", and " .. (playerCount - 3) .. " others"
	else
		displayNames = FormatNameList(players)
	end
	
	-- Replace placeholders
	message = message:gsub("{players}", displayNames)
	message = message:gsub("{player}", displayNames) -- alias
	message = message:gsub("{count}", tostring(playerCount))
	message = message:gsub("{achievement}", achievementName)
	message = message:gsub("{category}", achievementCategory or "General")
	
	return message
	end
	
-- Clear the achievement batch
local function ClearBatch()
	achievementBatch.isCollecting = false
	achievementBatch.startTime = 0
	achievementBatch.playerAchievements = {}
	achievementBatch.achievementPlayers = {}
	achievementBatch.achievementInfo = {}
end

-- Process the collected batch and send appropriate messages
local function ProcessBatch()
	DebugPrint("Processing achievement batch...")
	
	if not GuildAchieves.db.profile.IsEnabled then
		DebugPrint("Addon disabled, clearing batch")
		ClearBatch()
		return
	end
	
	-- Analyze the batch to determine the best way to congratulate
	-- Priority: 
	-- 1. If same achievement earned by multiple players, group them
	-- 2. If one player earned multiple achievements, combine them
	-- 3. Otherwise, send individual messages (but we shouldn't hit this often)
	
	local messagesToSend = {}
	local processedPlayers = {}
	local processedAchievements = {}
	
	-- First pass: Handle group achievements (same achievement, multiple players)
	local myName = UnitName("player")
	for achievementID, players in pairs(achievementBatch.achievementPlayers) do
		if #players > 1 then
			local info = achievementBatch.achievementInfo[achievementID]
			if info then
				-- Check if category is enabled
				local categoryEnabled = GuildAchieves.db.profile.CategoryToggles[info.category] ~= false
				if categoryEnabled then
					-- Filter out self if CongratsSelf is disabled
					local filteredPlayers = {}
					for _, player in ipairs(players) do
						if player == myName and not GuildAchieves.db.profile.CongratsSelf then
							DebugPrint("Excluding self from group achievement:", info.name)
						else
							table.insert(filteredPlayers, player)
						end
					end
					
					-- Only send group message if there are still multiple players
					if #filteredPlayers > 1 then
						local message = GetGroupAchievementMessage(info.name, info.category, filteredPlayers)
						table.insert(messagesToSend, message)
					elseif #filteredPlayers == 1 then
						-- Only one other person - send them an individual message instead
						local playerName = filteredPlayers[1]
						local message = GetRandomMessage(info.category, info.level, playerName, info.name)
						if message then
							table.insert(messagesToSend, message)
						end
					end
					-- If filteredPlayers is empty (only self was in the list), send nothing
					
					-- Mark ALL original players as processed for this achievement
					processedAchievements[achievementID] = true
					for _, player in ipairs(players) do
						if not processedPlayers[player] then
							processedPlayers[player] = {}
						end
						processedPlayers[player][achievementID] = true
					end
				end
			end
		end
	end
	
	-- Second pass: Handle multi-achievement players (one player, multiple achievements)
	for playerName, achievements in pairs(achievementBatch.playerAchievements) do
		-- Check if this is the player themselves and CongratsSelf is disabled
		local isSelf = playerName == UnitName("player")
		if isSelf and not GuildAchieves.db.profile.CongratsSelf then
			DebugPrint("Self achievements detected, skipping (CongratsSelf disabled) for", playerName)
			-- Skip all processing for self if CongratsSelf is disabled
		else
			-- Filter out already processed achievements
			local unprocessedAchievements = {}
			for _, achieve in ipairs(achievements) do
				if not (processedPlayers[playerName] and processedPlayers[playerName][achieve.id]) then
					-- Check if category is enabled
					local categoryEnabled = GuildAchieves.db.profile.CategoryToggles[achieve.category] ~= false
					if categoryEnabled then
						table.insert(unprocessedAchievements, achieve)
					end
				end
			end
			
			if #unprocessedAchievements > 1 then
				-- Multiple achievements for this player - combine them
				local message = GetMultiAchievementMessage(playerName, unprocessedAchievements)
				table.insert(messagesToSend, message)
			elseif #unprocessedAchievements == 1 then
				-- Single achievement - use normal message
				local achieve = unprocessedAchievements[1]
				local message = GetRandomMessage(achieve.category, achieve.level, playerName, achieve.name)
				if message then
					table.insert(messagesToSend, message)
				end
			end
		end
	end
	
	-- Send the messages with slight delays between them
	local delay = 0.5 + math.random() * 1.5 -- Initial delay 0.5-2 seconds
	
	for i, message in ipairs(messagesToSend) do
		C_Timer.After(delay, function()
			if GuildAchieves.db.profile.IsEnabled then
				-- Truncate message if too long (WoW chat limit is ~255 chars)
				if #message > 250 then
					message = message:sub(1, 247) .. "..."
				end
				SendGuildChat(message)
				lastMessageTime = GetTime()
			end
		end)
		delay = delay + 0.3 -- Small gap between multiple messages
	end
	
	-- Clear the batch
	ClearBatch()
	DebugPrint("Batch processing complete, sent", #messagesToSend, "messages")
end

-- Add an achievement to the current batch
local function AddToBatch(playerName, achievementID, achievementName, category, level)
	-- Initialize player's achievement list if needed
	if not achievementBatch.playerAchievements[playerName] then
		achievementBatch.playerAchievements[playerName] = {}
	end
	
	-- Check if we already have this achievement for this player (prevent duplicates)
	for _, existing in ipairs(achievementBatch.playerAchievements[playerName]) do
		if existing.id == achievementID then
			DebugPrint("Duplicate achievement in batch, skipping:", achievementName, "for", playerName)
			return
		end
	end
	
	-- Add to player's achievements
	table.insert(achievementBatch.playerAchievements[playerName], {
		id = achievementID,
		name = achievementName,
		category = category,
		level = level
	})
	
	-- Initialize achievement's player list if needed
	if not achievementBatch.achievementPlayers[achievementID] then
		achievementBatch.achievementPlayers[achievementID] = {}
	end
	
	-- Add player to this achievement's list
	table.insert(achievementBatch.achievementPlayers[achievementID], playerName)
	
	-- Store achievement info
	if not achievementBatch.achievementInfo[achievementID] then
		achievementBatch.achievementInfo[achievementID] = {
			name = achievementName,
			category = category,
			level = level
		}
	end
	
	DebugPrint("Added to batch:", playerName, "-", achievementName, "(", category, ")")
end

-- Start collecting achievements if not already
local function StartBatchCollection()
	if not achievementBatch.isCollecting then
		achievementBatch.isCollecting = true
		achievementBatch.startTime = GetTime()
		
		-- Schedule batch processing after the window
		C_Timer.After(BATCH_WINDOW, function()
			if achievementBatch.isCollecting then
				ProcessBatch()
			end
		end)
		
		DebugPrint("Started batch collection, will process in", BATCH_WINDOW, "seconds")
	end
end

-- =============================================================================
-- Level-Up Polling System
-- Only active on flavors without achievements (Burning Crusade Classic, WoW: Forever).
-- Polls guild roster every 30 seconds to detect milestone level-ups.
-- Only tracks players while they are online - goes offline = tracking cleared.
-- Only congratulates on actual dings (must see the previous level first).
-- Verifies guild membership before congratulating.
-- =============================================================================

-- Ask the server for fresh roster data. The global GuildRoster() exists on Classic
-- clients; the modern client (which WoW: Forever runs on) moved it to C_GuildInfo.
local function RequestGuildRoster()
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	elseif GuildRoster then
		GuildRoster()
	end
end

local function BCCPollGuildRoster()
	if not GuildAchieves.db or not GuildAchieves.db.profile.IsEnabled then return end
	if not IsInGuild() then return end

	-- Request fresh roster data from server
	RequestGuildRoster()

	local numMembers = GetNumGuildMembers()
	if numMembers == 0 then return end
	
	local currentOnline = {}
	local myName = UnitName("player")
	local myGUID = UnitGUID and UnitGUID("player") or nil
	local dings = {}
	-- On WoW: Forever every level is a ding (unless the user turned that off); BCC only does milestones
	local everyLevel = isForever and GuildAchieves.db.profile.ForeverEveryLevel ~= false

	for i = 1, numMembers do
		-- Return order: name, rankName, rankIndex, level, classDisplayName, zone, publicNote,
		-- officerNote, isOnline, status, classToken (e.g. "WARRIOR"), achievementPoints,
		-- achievementRank, isMobile, canSoR, repStanding, guid
		local fullName, _, _, level, classDisplayName, _, _, _, isOnline, _, classToken, _, _, _, _, _, guid = GetGuildRosterInfo(i)
		if fullName and isOnline and level and level > 0 then
			local name = fullName:match("([^%-]+)") or fullName
			currentOnline[name] = { level = level, class = classToken, className = classDisplayName }
			-- Self check by GUID: on WoW: Forever the roster name carries a surname ("Lye Shamin")
			-- while UnitName("player") may not, so a plain name comparison can miss.
			local isSelf = (guid ~= nil and myGUID ~= nil and guid == myGUID) or (name == myName)

			local previous = bccTracker.onlineLevels[name]
			if previous and level > previous.level then
				local dingLevel
				if everyLevel then
					-- Congratulate the level they're at now. One message even if they gained several
					-- levels between polls, so rapid low-level dings don't flood guild chat.
					dingLevel = level
				else
					-- Find the HIGHEST milestone crossed since last poll
					for milestone, _ in pairs(LEVEL_MILESTONES) do
						if milestone > previous.level and milestone <= level then
							if not dingLevel or milestone > dingLevel then
								dingLevel = milestone
							end
						end
					end
				end
				if dingLevel then
					-- Skip self unless CongratsSelf is enabled
					if not isSelf or GuildAchieves.db.profile.CongratsSelf then
						table.insert(dings, { name = name, level = dingLevel, class = classToken, className = classDisplayName })
						DebugPrint("Level-up detected:", name, "reached level", dingLevel, "(was", previous.level, ")")
					end
				end
			elseif not previous then
				-- First time seeing this player online - just record their level, don't congratulate
				-- This prevents false congratulations for players who just logged in or joined the guild
				DebugPrint("First time seeing", name, "online at level", level, "- recording without congratulation")
			end
		end
	end

	-- Replace tracking table with ONLY currently online players
	-- When a player goes offline, their entry is removed
	-- When they come back online, they're treated as "first seen" (no congratulation for offline progress)
	bccTracker.onlineLevels = currentOnline

	if #dings == 0 then return end

	-- Check if Level category is enabled
	if GuildAchieves.db.profile.CategoryToggles.Level == false then
		DebugPrint("Level category disabled, skipping", #dings, "level-up(s)")
		return
	end

	local function SendGuildMessage(message)
		if #message > 250 then
			message = message:sub(1, 247) .. "..."
		end
		SendGuildChat(message)
		lastMessageTime = GetTime()
	end

	-- Many dings in one poll: send a single combined message instead of a wall of them
	if isForever and #dings > MULTI_DING_THRESHOLD then
		C_Timer.After(1.0 + math.random() * 2.0, function()
			if not GuildAchieves.db or not GuildAchieves.db.profile.IsEnabled then return end
			local message = GetForeverMultiDingMessage(dings)
			if message then
				SendGuildMessage(message)
				DebugPrint("Sent combined level-up message for", #dings, "players")
			end
		end)
		return
	end

	-- Send congratulation messages with natural-looking delays
	local delay = 1.0 + math.random() * 2.0  -- 1-3 second initial delay
	for _, ding in ipairs(dings) do
		C_Timer.After(delay, function()
			if not GuildAchieves.db or not GuildAchieves.db.profile.IsEnabled then return end

			-- Verify player is still in guild and online (they appear in current tracking)
			if not bccTracker.onlineLevels[ding.name] then
				DebugPrint("Player", ding.name, "no longer online or in guild, skipping congratulation")
				return
			end

			local message = GetLevelUpMessage(ding)
			if message then
				SendGuildMessage(message)
				DebugPrint("Sent level-up message for", ding.name, "reaching level", ding.level)
			end
		end)
		delay = delay + 1.0 + math.random() * 1.0  -- 1-2 second gap between multiple messages
	end
end

local function StartBCCTracking()
	if bccTracker.ticker then return end  -- Already running
	
	DebugPrint("Starting level-up tracking (polling every", bccTracker.POLL_INTERVAL, "seconds)")

	-- Request initial roster data
	RequestGuildRoster()
	
	-- Initial population scan after a short delay for roster data to arrive
	C_Timer.After(3, function()
		BCCPollGuildRoster()
		DebugPrint("BCC: Initial roster scan complete")
	end)
	
	-- Start the periodic polling ticker
	bccTracker.ticker = C_Timer.NewTicker(bccTracker.POLL_INTERVAL, BCCPollGuildRoster)
end

local function StopBCCTracking()
	if bccTracker.ticker then
		bccTracker.ticker:Cancel()
		bccTracker.ticker = nil
	end
	bccTracker.onlineLevels = {}
	DebugPrint("BCC level-up tracking stopped")
end

-- Handle guild achievement event
local function OnGuildAchievement(playerName, achievementID)
	-- Guard against the event firing before OnInitialize has finished setting up self.db
	-- (can happen at login if the server queues up guild achievement messages before our init completes)
	if not GuildAchieves.db or not GuildAchieves.db.profile then
		DebugPrint("DB not ready yet, ignoring achievement (will catch future ones)")
		return
	end
	if not GuildAchieves.db.profile.IsEnabled then
		DebugPrint("Addon disabled, ignoring achievement")
		return
	end
	
	-- Check cooldown (but still collect for batching to avoid missing group achievements)
	local currentTime = GetTime()
	if currentTime - lastMessageTime < MESSAGE_COOLDOWN then
		DebugPrint("Cooldown active, but still collecting for batch")
		-- Continue processing - we'll handle cooldown in batch processing
	end
	
	-- Get achievement info
	local _, achievementName = GetAchievementInfo(achievementID)
	if not achievementName then
		DebugPrint("Could not get achievement name for ID:", achievementID)
		return
	end
	
	-- Determine category
	local category, level = GetAchievementCategoryInfo(achievementID)
	DebugPrint("Achievement:", achievementName, "Category:", category, "Level:", level or "N/A")
	
	-- Start batch collection if not already active
	StartBatchCollection()
	
	-- Add this achievement to the batch
	-- Note: We defer the self-check and category-enabled check to batch processing
	-- This allows us to properly handle group achievements where we might be included
	AddToBatch(playerName, achievementID, achievementName, category, level)
end

-- Event handler
function GuildAchieves:CHAT_MSG_GUILD_ACHIEVEMENT(event, message, playerName, ...)
	DebugPrint("CHAT_MSG_GUILD_ACHIEVEMENT fired!")
	DebugPrint("Message:", message)
	DebugPrint("Player:", playerName)
	
	-- Extract achievement ID from the message link
	-- Format: |cffffff00|Hachievement:ID:GUID:0:0:0:0:0:0:0:0|h[Achievement Name]|h|r
	local achievementID = tonumber(message:match("|Hachievement:(%d+)"))
	
	-- Alternative pattern if first doesn't match
	if not achievementID then
		achievementID = tonumber(message:match("achievement:(%d+)"))
	end
	
	DebugPrint("Extracted Achievement ID:", achievementID or "NONE")
	
	if achievementID then
		-- Clean player name (remove realm)
		local cleanName = playerName:match("([^%-]+)") or playerName
		DebugPrint("Clean player name:", cleanName)
		OnGuildAchievement(cleanName, achievementID)
	else
		DebugPrint("Could not extract achievement ID from message")
		-- Print the raw message to help debug
		self:Print("[DEBUG] Raw message: " .. tostring(message))
	end
end

-- Options table
local options = {
	type = 'group',
	name = 'Guild Achieves',
	desc = 'Guild Achieves addon settings',
	args = {
		-- Header
		header = {
			order = 1,
			type = 'header',
			name = 'Guild Achieves Settings',
		},
		
		-- General Settings Group
		general = {
			order = 10,
			type = 'group',
			name = 'General',
			desc = 'General addon settings',
			inline = true,
			args = {
				enable = {
					order = 1,
					type = 'toggle',
					name = 'Enable Guild Achieves',
					desc = 'Enable or disable the entire Guild Achieves addon',
					get = function() return GuildAchieves.db.profile.IsEnabled end,
					set = function(info, value) 
						GuildAchieves.db.profile.IsEnabled = value
						if value then
							GuildAchieves:Enable()
							-- AceAddon's Enable() is a no-op if the addon object is already enabled (it always is
							-- after login), so OnEnable won't re-run. Start milestone tracking directly; it's idempotent.
							if useLevelTracking then StartBCCTracking() end
							GuildAchieves:Print("Guild Achieves enabled!")
						else
							GuildAchieves:Disable()
							GuildAchieves:Print("Guild Achieves disabled.")
						end
					end,
					width = 'full',
				},
				congratsSelf = {
					order = 2,
					type = 'toggle',
					name = 'Congratulate Yourself',
					desc = 'Send congratulations when you earn achievements too',
					get = function() return GuildAchieves.db.profile.CongratsSelf end,
					set = function(info, value) 
						GuildAchieves.db.profile.CongratsSelf = value
					end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				foreverEveryLevel = {
					order = 2.5,
					type = 'toggle',
					name = 'Congratulate Every Level',
					desc = 'WoW: Forever has no achievements, so guildies are congratulated on level-ups instead. On: every level dings. Off: only milestones (10, 20, 30, 40, 50, 60).',
					get = function() return GuildAchieves.db.profile.ForeverEveryLevel ~= false end,
					set = function(info, value)
						GuildAchieves.db.profile.ForeverEveryLevel = value
					end,
					hidden = function() return not isForever end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
					width = 'full',
				},
				showMinimapButton = {
					order = 3,
					type = 'toggle',
					name = 'Show Minimap Button',
					desc = 'Show or hide the minimap button',
					get = function() return GuildAchieves.db.profile.ShowMinimapButton end,
					set = function(info, value) 
						GuildAchieves.db.profile.ShowMinimapButton = value
						if GuildAchieves.minimapButton then
							if value then
								GuildAchieves.minimapButton:Show()
							else
								GuildAchieves.minimapButton:Hide()
							end
						end
					end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				uiTemplate = {
					order = 4,
					type = 'select',
					name = 'UI Template',
					desc = 'Choose the visual style for the interface',
					get = function() return GuildAchieves.db.profile.UITemplate end,
					set = function(info, value) 
						GuildAchieves.db.profile.UITemplate = value
						GuildAchieves:Print("UI Template changed to: " .. value)
						InitializeClassColor()
						UpdateTemplateColors(value)
					end,
					values = {
						["Default"] = "Default - Solid black with gold text",
						["Transparent"] = "Transparent - 70% opacity with white text",
						["ClassColor"] = "Class Color - 80% opacity with class colors"
					},
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
			},
		},
		
		-- Timing Settings
		timing = {
			order = 20,
			type = 'group',
			name = 'Timing',
			desc = 'Message timing settings',
			inline = true,
			args = {
				cooldown = {
					order = 1,
					type = 'range',
					name = 'Message Cooldown',
					desc = 'Minimum seconds between congratulatory messages (prevents spam)',
					min = 0,
					max = 30,
					step = 1,
					get = function() return GuildAchieves.db.profile.Cooldown or 5 end,
					set = function(info, value) 
						GuildAchieves.db.profile.Cooldown = value
						MESSAGE_COOLDOWN = value
					end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
					width = 'full',
				},
				cooldownInfo = {
					order = 2,
					type = 'description',
					name = 'The cooldown prevents spam when multiple guildies earn achievements rapidly.',
					fontSize = 'medium',
				},
			},
		},
		
		-- Category Toggles
		categories = {
			order = 30,
			type = 'group',
			name = 'Categories',
			desc = 'Enable or disable messages for specific achievement categories',
			inline = true,
			args = {
				levelToggle = {
					order = 1,
					type = 'toggle',
					name = 'Level Achievements',
					desc = 'Send messages for level-up achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Level ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Level = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				questsToggle = {
					order = 2,
					type = 'toggle',
					name = 'Quest Achievements',
					desc = 'Send messages for quest completion achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Quests ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Quests = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				explorationToggle = {
					order = 3,
					type = 'toggle',
					name = 'Exploration Achievements',
					desc = 'Send messages for exploration achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Exploration ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Exploration = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				dungeonsToggle = {
					order = 4,
					type = 'toggle',
					name = 'Dungeon Achievements',
					desc = 'Send messages for dungeon achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Dungeons ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Dungeons = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				raidsToggle = {
					order = 5,
					type = 'toggle',
					name = 'Raid Achievements',
					desc = 'Send messages for raid achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Raids ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Raids = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				pvpToggle = {
					order = 6,
					type = 'toggle',
					name = 'PvP Achievements',
					desc = 'Send messages for PvP achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.PvP ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.PvP = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				professionsToggle = {
					order = 7,
					type = 'toggle',
					name = 'Profession Achievements',
					desc = 'Send messages for profession achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Professions ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Professions = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				reputationToggle = {
					order = 8,
					type = 'toggle',
					name = 'Reputation Achievements',
					desc = 'Send messages for reputation achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Reputation ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Reputation = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				petBattlesToggle = {
					order = 9,
					type = 'toggle',
					name = 'Pet Battle Achievements',
					desc = 'Send messages for pet battle achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.PetBattles ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.PetBattles = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				scenariosToggle = {
					order = 10,
					type = 'toggle',
					name = 'Scenario Achievements',
					desc = 'Send messages for scenario achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.Scenarios ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.Scenarios = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				worldEventsToggle = {
					order = 11,
					type = 'toggle',
					name = 'World Event Achievements',
					desc = 'Send messages for holiday/world event achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.WorldEvents ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.WorldEvents = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				generalToggle = {
					order = 12,
					type = 'toggle',
					name = 'General Achievements',
					desc = 'Send messages for uncategorized/general achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.General ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.General = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				-- Midnight (12.0.1) category header
				midnightHeader = {
					order = 13,
					type = 'header',
					name = 'Midnight (12.0.1) Categories',
				},
				midnightRaidsToggle = {
					order = 14,
					type = 'toggle',
					name = 'Midnight Raids',
					desc = 'Voidspire, Dreamrift, March on Quel\'Danas',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightRaids ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightRaids = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightKeystonesToggle = {
					order = 15,
					type = 'toggle',
					name = 'Midnight Keystones',
					desc = 'Midnight Mythic+ and keystone achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightKeystones ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightKeystones = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightDelvesToggle = {
					order = 16,
					type = 'toggle',
					name = 'Midnight Delves',
					desc = 'Delve achievements from the Midnight expansion',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightDelves ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightDelves = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightExplorationToggle = {
					order = 17,
					type = 'toggle',
					name = 'Midnight Exploration',
					desc = 'Quel\'Thalas, Zul\'Aman, Harandar, Voidstorm exploration',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightExploration ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightExploration = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightPreyToggle = {
					order = 18,
					type = 'toggle',
					name = 'Prey System',
					desc = 'Preyseeker\'s Journey and hunt achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightPrey ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightPrey = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightHousingToggle = {
					order = 19,
					type = 'toggle',
					name = 'Housing',
					desc = 'New Midnight housing achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightHousing ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightHousing = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightClassToggle = {
					order = 20,
					type = 'toggle',
					name = 'Midnight Class',
					desc = 'Class-specific Midnight achievements (Devourer DH, etc.)',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightClass ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightClass = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				midnightHaranirToggle = {
					order = 21,
					type = 'toggle',
					name = 'Haranir',
					desc = 'Haranir allied race achievements',
					get = function() return GuildAchieves.db.profile.CategoryToggles.MidnightHaranir ~= false end,
					set = function(info, value) GuildAchieves.db.profile.CategoryToggles.MidnightHaranir = value end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
			},
		},
		
		-- Test & Debug
		advanced = {
			order = 40,
			type = 'group',
			name = 'Advanced',
			desc = 'Testing and debugging options',
			inline = true,
			args = {
				testMessage = {
					order = 1,
					type = 'execute',
					name = 'Test Message',
					desc = 'Send a test congratulation message to guild chat',
					func = function()
						local testMsg = GetRandomMessage("General", nil, UnitName("player"), "Test Achievement")
						if testMsg then
							GuildAchieves:Print("Test message (not sent to guild): " .. testMsg)
						else
							GuildAchieves:Print("Could not generate test message - check that achievement data is loaded")
						end
					end,
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				sendTestNow = {
					order = 1.1,
					type = 'execute',
					name = 'Send Test to Guild',
					desc = 'Actually sends a short test line to guild chat right now (from this click, which counts as a hardware event). Use with Debug Mode on to see which chat API was used and whether the client reports a chat lockdown.',
					func = function()
						-- Bypass the queue on purpose: this click is itself a hardware event
						SendGuildChatNow("Guild Achieves test (immediate): if you can read this, guild chat sending works.")
					end,
					confirm = true,
					confirmText = 'This will post a test line in guild chat. Continue?',
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				sendTestDelayed = {
					order = 1.2,
					type = 'execute',
					name = 'Send Test to Guild (3s delay)',
					desc = 'Same as above, but sent from a timer 3 seconds later, the way level-up and achievement messages are sent. On clients that block timer-driven guild chat (WoW: Forever) it is queued and goes out on your next key press, world click, jump, or chat line.',
					func = function()
						GuildAchieves:Print("Sending a test line to guild chat in 3 seconds...")
						C_Timer.After(3, function()
							SendGuildChat("Guild Achieves test (delayed): if you can read this, timer-driven guild chat works.")
						end)
					end,
					confirm = true,
					confirmText = 'This will post a test line in guild chat after 3 seconds. Continue?',
					disabled = function() return not GuildAchieves.db.profile.IsEnabled end,
				},
				debugMode = {
					order = 2,
					type = 'toggle',
					name = 'Debug Mode',
					desc = 'Enable debug output to chat',
					get = function() return GuildAchieves.db.profile.DebugMode end,
					set = function(info, value) 
						GuildAchieves.db.profile.DebugMode = value
						GuildAchieves:Print("Debug mode " .. (value and "enabled" or "disabled"))
					end,
				},
				reloadUI = {
					order = 3,
					type = 'execute',
					name = 'Reload UI',
					desc = 'Reload the user interface',
					func = function() ReloadUI() end,
					confirm = true,
					confirmText = 'This will reload your UI. Continue?',
				},
			},
		},
	},
}

-- Create minimap button
local function CreateMinimapButton()
	local LDB = LibStub("LibDataBroker-1.1", true)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)
	
	if not LDB or not LDBIcon then
		DebugPrint("LibDataBroker or LibDBIcon not available")
		return
	end
	
	local dataObject = LDB:NewDataObject("GuildAchieves", {
		type = "launcher",
		icon = "Interface\\Icons\\Achievement_guildperk_everybodysfriend",
		OnClick = function(self, button)
			if button == "LeftButton" then
				-- Toggle enabled state. Go through Enable()/Disable() (like the options panel toggle)
				-- so milestone level tracking on BCC / WoW: Forever starts and stops with the addon.
				GuildAchieves.db.profile.IsEnabled = not GuildAchieves.db.profile.IsEnabled
				if GuildAchieves.db.profile.IsEnabled then
					GuildAchieves:Enable()
					if useLevelTracking then StartBCCTracking() end  -- see options toggle for why
					GuildAchieves:Print("Guild Achieves enabled!")
				else
					GuildAchieves:Disable()
					GuildAchieves:Print("Guild Achieves disabled.")
				end
			elseif button == "RightButton" then
				-- Open settings - try modern Settings API first (Dragonflight+, Midnight),
				-- then fall back to older InterfaceOptionsFrame_OpenToCategory for Classic/BCC/Wrath
				-- Settings.OpenToCategory needs the category ID that AddToBlizOptions returned. On 12.0+
				-- clients (Midnight, WoW: Forever) that ID is numeric and the category name no longer works.
				if Settings and Settings.OpenToCategory and optionsCategoryID then
					Settings.OpenToCategory(optionsCategoryID)
				elseif InterfaceOptionsFrame_OpenToCategory then
					InterfaceOptionsFrame_OpenToCategory("Guild Achieves")
					InterfaceOptionsFrame_OpenToCategory("Guild Achieves") -- called twice (Blizzard bug workaround)
				else
					GuildAchieves:Print("Type /ga or /guildachieves to open settings.")
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Guild Achieves")
			tooltip:AddLine(" ")
			local status = GuildAchieves.db.profile.IsEnabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"
			tooltip:AddLine("Status: " .. status)
			tooltip:AddLine(" ")
			tooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle on/off")
			tooltip:AddLine("|cFFFFFFFFRight-click:|r Open settings")
		end,
	})
	
	LDBIcon:Register("GuildAchieves", dataObject, GuildAchieves.db.profile.minimapIcon)
	
	GuildAchieves.minimapButton = LDBIcon
	DebugPrint("Minimap button created")
end

-- Addon initialization
function GuildAchieves:OnInitialize()
	DebugPrint("GuildAchieves:OnInitialize called")

	-- Register options
	LibStub("AceConfig-3.0"):RegisterOptionsTable("GuildAchieves", options, {"guildachieves", "ga"})
	
	-- Register with Interface Options
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	-- Keep the returned category ID: it's what Settings.OpenToCategory expects (see minimap right-click)
	local _, categoryID = AceConfigDialog:AddToBlizOptions("GuildAchieves", "Guild Achieves")
	optionsCategoryID = categoryID
	
	-- Default settings
	defaults = {
		profile = {
			IsEnabled = true,
			CongratsSelf = false,
			ForeverEveryLevel = true,  -- WoW: Forever only: congratulate every level, not just milestones
			ShowMinimapButton = true,
			UITemplate = "Default",
			Cooldown = 5,
			DebugMode = false,
			CategoryToggles = {
				Level = true,
				Quests = true,
				Exploration = true,
				Dungeons = true,
				Raids = true,
				PvP = true,
				Professions = true,
				Reputation = true,
				PetBattles = true,
				Scenarios = true,
				WorldEvents = true,
				General = true,
				-- Midnight (12.0.1) categories
				MidnightRaids = true,
				MidnightKeystones = true,
				MidnightDelves = true,
				MidnightExploration = true,
				MidnightPrey = true,
				MidnightHousing = true,
				MidnightClass = true,
				MidnightHaranir = true,
			},
			minimapIcon = {
				hide = false,
			},
		}
	}
	
	-- Initialize database
	self.db = LibStub("AceDB-3.0"):New("GuildAchievesDB", defaults, true)
	db = self.db.profile
	
	-- Update cooldown from saved settings
	MESSAGE_COOLDOWN = self.db.profile.Cooldown or 5
	
	-- Initialize UI colors
	InitializeClassColor()
	UpdateTemplateColors(self.db.profile.UITemplate)
	
	-- Create minimap button
	CreateMinimapButton()

	-- Register events AFTER db is initialized so the handler can safely read profile settings
	-- Uses our private unnamed eventFrame (see top of file) to avoid the Midnight 12.0
	-- AceEvent30Frame shared-frame taint bug.
	if not isBCC then
		-- WoW: Forever runs on the modern client, so the event exists even though the
		-- achievement system itself doesn't appear to. Registering it is harmless there and
		-- means we'd pick achievements up automatically if Blizzard ever enables them.
		-- pcall guards against the event being unknown on an unexpected client build.
		local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, "CHAT_MSG_GUILD_ACHIEVEMENT")
		if not ok then
			DebugPrint("Could not register CHAT_MSG_GUILD_ACHIEVEMENT:", tostring(err))
		end
	end
	-- Hardware-event chat queue support: learn when a direct send is blocked, and keep the
	-- keyboard watcher hidden during combat (see the guild chat sending section near the top)
	for _, eventName in ipairs({ "ADDON_ACTION_BLOCKED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
		local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, eventName)
		if not ok then
			DebugPrint("Could not register", eventName, ":", tostring(err))
		end
	end

	DebugPrint("GuildAchieves initialized successfully")
	if isForever then
		self:Print("Guild Achieves loaded (WoW: Forever)! Tracking milestone level-ups. Type /ga for options.")
	elseif isBCC then
		self:Print("Guild Achieves loaded (Burning Crusade Classic)! Tracking milestone level-ups. Type /ga for options.")
	elseif isMidnight then
		self:Print("Guild Achieves loaded (Midnight 12.0.1)! Type /guildachieves or /ga for options.")
	else
		self:Print("Guild Achieves loaded! Type /guildachieves or /ga for options.")
	end
end

function GuildAchieves:OnEnable()
	DebugPrint("GuildAchieves:OnEnable called")
	if useLevelTracking and self.db and self.db.profile.IsEnabled then
		-- Start milestone level tracking with a delay for guild data to load
		C_Timer.After(5, function()
			if self.db.profile.IsEnabled then
				StartBCCTracking()
			end
		end)
	end
end

function GuildAchieves:OnDisable()
	DebugPrint("GuildAchieves:OnDisable called")
	if useLevelTracking then
		StopBCCTracking()
	end
end

