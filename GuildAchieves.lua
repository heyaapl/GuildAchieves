-- Author      : heyaapl
-- Create Date : 12/28/2024
-- Guild Achieves - Automatically congratulates guildies on achievements with humorous messages!

GuildAchieves = LibStub("AceAddon-3.0"):NewAddon("GuildAchieves", "AceConsole-3.0", "AceEvent-3.0")

-- GLOBALS: GuildAchieves, GuildAchievesData

-- Local references
local db
local defaults

-- Cooldown tracking to prevent spam
local lastMessageTime = 0
local MESSAGE_COOLDOWN = 5 -- seconds between messages

-- Debug system
local function DebugPrint(...)
	if GuildAchieves and GuildAchieves.db and GuildAchieves.db.profile and GuildAchieves.db.profile.DebugMode then
		GuildAchieves:Print("[DEBUG]", ...)
	end
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

-- Get category from achievement ID
local function GetAchievementCategoryInfo(achievementID)
	-- Check if it's a level achievement first
	if LEVEL_ACHIEVEMENT_IDS[achievementID] then
		return "Level", LEVEL_ACHIEVEMENT_IDS[achievementID]
	end
	
	-- Get achievement info using WoW API
	local _, name = GetAchievementInfo(achievementID)
	
	-- Get the category using WoW API (not our function!)
	local categoryID = select(1, GetAchievementCategory(achievementID))
	if categoryID and ACHIEVEMENT_CATEGORIES[categoryID] then
		return ACHIEVEMENT_CATEGORIES[categoryID], nil
	end
	
	-- Try parent category
	if categoryID then
		local _, parentID = GetCategoryInfo(categoryID)
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
		
		-- Category detection by keywords
		if lowerName:match("explor") then return "Exploration", nil end
		if lowerName:match("dungeon") or lowerName:match("heroic") then return "Dungeons", nil end
		if lowerName:match("raid") or lowerName:match("boss") then return "Raids", nil end
		if lowerName:match("arena") or lowerName:match("battleground") or lowerName:match("honorable") then return "PvP", nil end
		if lowerName:match("craft") or lowerName:match("skill") or lowerName:match("profession") then return "Professions", nil end
		if lowerName:match("reputation") or lowerName:match("exalted") then return "Reputation", nil end
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
	
	-- For level achievements, get level-specific messages
	if category == "Level" and level then
		if GuildAchievesData.Levels and GuildAchievesData.Levels[level] then
			messages = GuildAchievesData.Levels[level]
		end
	end
	
	-- Fall back to category messages
	if not messages or #messages == 0 then
		if GuildAchievesData.Categories and GuildAchievesData.Categories[category] then
			messages = GuildAchievesData.Categories[category]
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

-- Handle guild achievement event
local function OnGuildAchievement(playerName, achievementID)
	if not GuildAchieves.db.profile.IsEnabled then
		DebugPrint("Addon disabled, ignoring achievement")
		return
	end
	
	-- Check cooldown
	local currentTime = GetTime()
	if currentTime - lastMessageTime < MESSAGE_COOLDOWN then
		DebugPrint("Cooldown active, skipping message")
		return
	end
	
	-- Don't congratulate yourself
	if playerName == UnitName("player") and not GuildAchieves.db.profile.CongratsSelf then
		DebugPrint("Self achievement, skipping (CongratsSelf disabled)")
		return
	end
	
	-- Get achievement info
	local _, achievementName = GetAchievementInfo(achievementID)
	
	-- Determine category
	local category, level = GetAchievementCategoryInfo(achievementID)
	DebugPrint("Achievement:", achievementName, "Category:", category, "Level:", level or "N/A")
	
	-- Check if this category is enabled
	local categoryEnabled = true
	if GuildAchieves.db.profile.CategoryToggles and GuildAchieves.db.profile.CategoryToggles[category] == false then
		categoryEnabled = false
		DebugPrint("Category", category, "is disabled")
		return
	end
	
	-- Get message
	local message = GetRandomMessage(category, level, playerName, achievementName)
	if not message then
		DebugPrint("No message generated")
		return
	end
	
	-- Random delay 1-3 seconds
	local delay = 1 + math.random() * 2
	DebugPrint("Sending message in", string.format("%.1f", delay), "seconds")
	
	C_Timer.After(delay, function()
		-- Double-check we're still enabled
		if not GuildAchieves.db.profile.IsEnabled then return end
		
		-- Send to guild chat
		SendChatMessage(message, "GUILD")
		lastMessageTime = GetTime()
		DebugPrint("Sent:", message)
	end)
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
		icon = "Interface\\AddOns\\GuildAchieves\\icon",
		OnClick = function(self, button)
			if button == "LeftButton" then
				-- Toggle enabled state
				GuildAchieves.db.profile.IsEnabled = not GuildAchieves.db.profile.IsEnabled
				if GuildAchieves.db.profile.IsEnabled then
					GuildAchieves:Print("Guild Achieves enabled!")
				else
					GuildAchieves:Print("Guild Achieves disabled.")
				end
			elseif button == "RightButton" then
				-- Open settings
				Settings.OpenToCategory("GuildAchieves")
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
	
	-- Register events
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
	
	-- Register options
	LibStub("AceConfig-3.0"):RegisterOptionsTable("GuildAchieves", options, {"guildachieves", "ga"})
	
	-- Register with Interface Options
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigDialog:AddToBlizOptions("GuildAchieves", "Guild Achieves")
	
	-- Default settings
	defaults = {
		profile = {
			IsEnabled = true,
			CongratsSelf = false,
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
	
	DebugPrint("GuildAchieves initialized successfully")
	self:Print("Guild Achieves loaded! Type /guildachieves or /ga for options.")
end

function GuildAchieves:OnEnable()
	DebugPrint("GuildAchieves:OnEnable called")
end

function GuildAchieves:OnDisable()
	DebugPrint("GuildAchieves:OnDisable called")
end

