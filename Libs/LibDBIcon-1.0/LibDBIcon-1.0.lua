-----------------------------------------------------------------------
-- LibDBIcon-1.0 - Simplified Version
--
-- Allows addons to easily create a lightweight minimap icon.
--

local MAJOR, MINOR = "LibDBIcon-1.0", 45
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.tooltip = lib.tooltip or CreateFrame("GameTooltip", "LibDBIconTooltip", UIParent, "GameTooltipTemplate")

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter(self)
	local obj = self.originalObject
	if obj and obj.OnTooltipShow then
		lib.tooltip:SetOwner(self, "ANCHOR_NONE")
		lib.tooltip:SetPoint(getAnchors(self))
		obj.OnTooltipShow(lib.tooltip)
		lib.tooltip:Show()
	elseif obj and obj.OnEnter then
		obj.OnEnter(self)
	end
end

local function onLeave(self)
	lib.tooltip:Hide()
	local obj = self.originalObject
	if obj and obj.OnLeave then
		obj.OnLeave(self)
	end
end

local function onClick(self, button)
	-- Debug output (only if debug is enabled in main addon)
	if _G.SoundboardDebug and _G.SoundboardDebug.enabled then
		print("LibDBIcon: Button clicked! Button:", button, "DataObject:", self.dataObject)
	end
	
	local obj = self.originalObject
	if obj and obj.OnClick then
		if _G.SoundboardDebug and _G.SoundboardDebug.enabled then
			print("LibDBIcon: Calling OnClick handler")
		end
		obj.OnClick(self, button)
	else
		if _G.SoundboardDebug and _G.SoundboardDebug.enabled then
			print("LibDBIcon: No OnClick handler found. Object:", obj)
		end
	end
end

local function createButton(name, object, db)
	-- Clean up any existing button first
	if lib.objects[name] then
		lib.objects[name]:Hide()
		lib.objects[name] = nil
	end
	
	local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
	button.dataObject = name
	button:SetFrameStrata("HIGH")
	button:SetSize(31, 31)
	button:SetFrameLevel(20)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:EnableMouse(true)
	button:SetMovable(true)
	button:SetClampedToScreen(true)
	
	-- Create the standard minimap button look
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")
	
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("TOPLEFT", 7, -5)
	
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)
	button.icon = icon
	
	-- Set up event handlers
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	
	-- Add simple drag functionality
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	button:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	
	-- Set highlight texture
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	
	-- Store both the button and the original object
	lib.objects[name] = button
	button.originalObject = object
	
	-- Set icon if provided
	if object.icon then 
		icon:SetTexture(object.icon) 
	end
	if object.iconCoords then 
		icon:SetTexCoord(unpack(object.iconCoords)) 
	end
	
	-- Position the button (default position)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", -52, -52)
	
	return button
end

function lib:Register(name, object, db)
	if not object.icon then 
		error("Can't register LDB object `"..name.."' without `icon' member") 
	end
	
	if db and db.hide then return end
	
	createButton(name, object, db)
end

function lib:Hide(name)
	if lib.objects[name] then
		lib.objects[name]:Hide()
	end
end

function lib:Show(name)
	if lib.objects[name] then
		lib.objects[name]:Show()
	end
end

function lib:IsRegistered(name)
	return lib.objects[name] ~= nil
end

function lib:GetMinimapButton(name)
	return lib.objects[name]
end

function lib:Refresh(name, db)
	local button = lib.objects[name]
	if button then
		if db and db.hide then
			button:Hide()
		else
			button:Show()
		end
	end
end

-- Simplified positioning functions
function lib:GetButtonPosition(name)
	return 225
end

function lib:SetButtonPosition(name, position)
	-- Not implemented in simplified version
end
