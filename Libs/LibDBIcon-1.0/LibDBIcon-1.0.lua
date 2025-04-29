--[[
Name: LibDBIcon-1.0
Revision: $Rev: 54 $
Author: Rabbit (rabbit.magtheridon@gmail.com)
License: GPL v2
Description: Allows addons to register to recieve a lightweight minimap icon as an alternative to more heavy LDB displays.
]]

local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 34 -- Bump on changes
if not LibStub then error(DBICON10 .. " requires LibStub.") end
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then error(DBICON10 .. " requires LibDataBroker-1.1.") end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or nil
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.radius = lib.radius or 80
lib.minimapShapes = lib.minimapShapes or {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local function getIconString(button)
	local waypoint = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
	if waypoint and button.realIcon == "Interface\\AddOns\\SpamAddon\\icon" then 
		return button.realIcon.."Tracked"
	end
	return button.realIcon or button.icon
end

function lib:IconCallback(event, name, key, value)
	if lib.objects[name] then
		lib.objects[name].icon = getIconString(lib.objects[name])
		lib.objects[name]:Refresh()
	end
end

function lib:Embed(target)
	target.RegisterDBIcon = target.RegisterDBIcon or function(self, broker, db)
		lib:Register(broker, db, self)
	end
	return target
end

function lib:OnInitialize()
	lib.radius = lib.radius or 80
	lib:SetupListeners()
	--hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function()
	--	for name, object in pairs(lib.objects) do
	--		object.icon = getIconString(object)
	--		object:Refresh()
	--	end
	--end)
end

function lib:Register(broker, db, optParent)
	if not broker then return end
	if not db or not db.hide then
		db = db or {}
		db.hide = false
	end
	
	local obj = {
		name = broker,
		parent = optParent,
		icon = getIconString({icon = ldb:GetDataObjectByName(broker)["icon"], realIcon = ldb:GetDataObjectByName(broker).icon, iconR = ldb:GetDataObjectByName(broker).iconR, iconG = ldb:GetDataObjectByName(broker).iconG, iconB = ldb:GetDataObjectByName(broker).iconB}),
		iconR = ldb:GetDataObjectByName(broker).iconR,
		iconG = ldb:GetDataObjectByName(broker).iconG,
		iconB = ldb:GetDataObjectByName(broker).iconB,
		iconCoords = ldb:GetDataObjectByName(broker).iconCoords,
		defaultCoords = ldb:GetDataObjectByName(broker).iconCoords or {0, 1, 0, 1},
		db = db
	}
	lib.objects[broker] = obj
	obj.button = lib:CreateButton(broker, obj, ldb:GetDataObjectByName(broker))
	if obj.db.hide and obj.button:IsShown() then
		obj.button:Hide()
	end
	if not lib.callbackRegistered then
		ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__icon", "IconCallback")
		ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconCoords", "IconCallback")
		ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconR", "IconCallback")
		ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconG", "IconCallback")
		ldb.RegisterCallback(lib, "LibDataBroker_AttributeChanged__iconB", "IconCallback")
		lib.callbackRegistered = true
	end
	obj.button:Refresh()
	return obj.button
end

function lib:SetupListeners()
	for broker, obj in pairs(lib.objects) do
		obj.button = lib:CreateButton(broker, obj, ldb:GetDataObjectByName(broker))
		if obj.db.hide and obj.button:IsShown() then
			obj.button:Hide()
		end
		obj.button:Refresh()
	end
end

function lib:CreateButton(name, obj, dataobj)
	local button = obj.parent and _G[obj.parent]:CreateButton(name) or Minimap:CreateButton(name)
	button.dataObject = dataobj
	button.owner = obj
	button.name = name
	
	local realIcon
	button.icon = getIconString(obj)
	button.realIcon = obj.realIcon
	button.iconR = obj.iconR
	button.iconG = obj.iconG
	button.iconB = obj.iconB
	button.iconCoords = obj.iconCoords or obj.defaultCoords
	
	local point, x, y	
	if obj.db and obj.db.minimapPos then
		point, x, y = "TOPLEFT", obj.db.minimapPos.x, obj.db.minimapPos.y
	else
		point, x, y = "TOPLEFT", -80, 80
	end
	button:SetPoint(point, x, y)
	
	if obj.db and obj.db.radius then
		button:SetClampedToScreen(true)
		button:SetFixedFrameStrata(true)
		button:SetFrameStrata("MEDIUM")
		button:SetFixedFrameLevel(true)
		button:SetFrameLevel(8)
		button:SetSize(20, 20)
		button:RegisterForClicks("anyUp")
		button:RegisterForDrag("LeftButton")
		button:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT")
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(20, 20)
		background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		background:SetPoint("TOPLEFT", 2, -2)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(16, 16)
		icon:SetTexture(obj.icon)
		
		if obj.iconCoords then
			icon:SetTexCoord(obj.iconCoords[1], obj.iconCoords[2], obj.iconCoords[3], obj.iconCoords[4])
		end
		
		if obj.iconR and obj.iconG and obj.iconB then
			icon:SetVertexColor(obj.iconR, obj.iconG, obj.iconB)
		end
		icon:SetPoint("TOPLEFT", 2, -2)
		button.icon = icon
		button.isMouseDown = false
		
		local r, g, b = 0.3, 0.3, 0.3
		button:SetScript("OnEnter", function(self) 
			if self.dataObject.OnEnter then
				self.dataObject.OnEnter(self)
			end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 20, -8)
			GameTooltip:SetText(self.dataObject.name or name)
			if self.dataObject.OnTooltipShow then
				self.dataObject.OnTooltipShow(GameTooltip)
			end
			GameTooltip:Show()
			self.icon:SetVertexColor(r, g, b) --1, 1, 1)
		end)
		button:SetScript("OnLeave", function(self) 
			if self.dataObject.OnLeave then
				self.dataObject.OnLeave(self)
			end
			GameTooltip:Hide()
			if obj.iconR and obj.iconG and obj.iconB then
				self.icon:SetVertexColor(obj.iconR, obj.iconG, obj.iconB)
			else
				self.icon:SetVertexColor(1, 1, 1)
			end
		end)
		button:SetScript("OnClick", function(self, button) 
			if self.dataObject.OnClick then
				self.dataObject.OnClick(self, button)
			end
		end)
		button:SetScript("OnMouseDown", function(self) 
			self.icon:SetPoint("TOPLEFT", 3, -3)
			self.isMouseDown = true 
		end)
		button:SetScript("OnMouseUp", function(self) 
			self.icon:SetPoint("TOPLEFT", 2, -2)
			self.isMouseDown = false 
		end)
		button:SetScript("OnDragStart", function(self)
			self:SetScript("OnUpdate", function(self) self:Move() end)
			self.isMouseDown = true
			self.icon:SetPoint("TOPLEFT", 3, -3)
			self:SetAlpha(0.8)
			self:LockHighlight()
		end)
		button:SetScript("OnDragStop", function(self)
			self:SetScript("OnUpdate", nil)
			self.isMouseDown = false
			self.icon:SetPoint("TOPLEFT", 2, -2)
			self:SetAlpha(1)
			self:UnlockHighlight()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale
			if obj.db and obj.db.minimapPos then
				obj.db.minimapPos.x = px - mx
				obj.db.minimapPos.y = py - my
			end
			obj.button:SetPoint("TOPLEFT", px - mx, py - my)
		end)
	end
	
	function button:Hide()
		return self:SetAlpha(0)
	end
	
	function button:Show()
		return self:SetAlpha(1)
	end
	
	function button:IsShown()
		return self:GetAlpha() > 0
	end
	
	function button:Move()
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		button:SetPoint("TOPLEFT", px - mx, py - my)
	end
	
	function button:Refresh()
		local tex = getIconString(self.owner)
		self.icon:SetTexture(tex)
		if self.owner.iconCoords or self.owner.defaultCoords then
			self.icon:SetTexCoord(self.owner.iconCoords and self.owner.iconCoords[1] or self.owner.defaultCoords[1], self.owner.iconCoords and self.owner.iconCoords[2] or self.owner.defaultCoords[2], self.owner.iconCoords and self.owner.iconCoords[3] or self.owner.defaultCoords[3], self.owner.iconCoords and self.owner.iconCoords[4] or self.owner.defaultCoords[4])
		end
		if self.owner.iconR and self.owner.iconG and self.owner.iconB then
			self.icon:SetVertexColor(self.owner.iconR, self.owner.iconG, self.owner.iconB)
		end
	end
	
	return button
end

-- Upgrade!
if not Minimap.CreateButton then
	Minimap.CreateButton = function(self, name)
		local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
		button.GetLibDBIconParent = function() return Minimap end
		return button
	end
end

function lib:GetMinimapShape()
	return GetMinimapShape and GetMinimapShape() or "ROUND"
end

function lib:GetButtonRadius()
	return self.radius
end

function lib:SetButtonRadius(radius)
	assert(type(radius) == "number", "Radius must be a number.")
	self.radius = radius
end

function lib:ShowOnEnter(broker, value)
	local obj = self.objects[broker]
	if obj then obj.showOnEnter = value end
end

function lib:ShowButton(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		self.objects[broker].db.hide = false
		if self.objects[broker].button and not self.objects[broker].button:IsShown() then
			self.objects[broker].button:Show()
		end
	end
end

function lib:HideButton(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		self.objects[broker].db.hide = true
		if self.objects[broker].button and self.objects[broker].button:IsShown() then
			self.objects[broker].button:Hide()
		end
	end
end

function lib:IsButtonVisible(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		return not self.objects[broker].db.hide
	end
end

function lib:GetLDBObjectByName(broker)
	return ldb:GetDataObjectByName(broker)
end

function lib:GetButtonDBForProfile(broker, db, profile)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	return db:GetNamespace(DBICON10, true) or db:RegisterNamespace(DBICON10).profiles[profile or db:GetCurrentProfile()]
end

function lib:RegisterOtherDB(broker, db, profile)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	local olddb = self.objects[broker].db
	local data = { hide = olddb.hide }
	if olddb.minimapPos then
		data.minimapPos = olddb.minimapPos
	end
	self.objects[broker].db = db:GetNamespace(DBICON10, true) or db:RegisterNamespace(DBICON10)
	self.objects[broker].db.profiles[profile or db:GetCurrentProfile()] = data
end

function lib:Lock(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		self.objects[broker].lockDragging = true
	end
end

function lib:Unlock(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		self.objects[broker].lockDragging = false
	end
end

function lib:IsLocked(broker)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker] then
		return self.objects[broker].lockDragging
	end
end

function lib:Refresh(broker, force)
	assert(self:GetLDBObjectByName(broker), "Invalid object name.")
	if self.objects[broker].button then
		self.objects[broker].button:Refresh();
	end
end

-- wait for PLAYER_LOGIN to init all LDB objects, which are usually created on ADDON_LOADED
local function Init(self)
	self:SetupListeners();
	self:UnregisterEvent("PLAYER_LOGIN");
	self.waitingForLogin = false;
end

if not lib.waitingForLogin then
	lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
	lib.eventFrame:RegisterEvent("PLAYER_LOGIN")
	lib.eventFrame:SetScript("OnEvent", Init)
	lib.waitingForLogin = true
end

lib:OnInitialize()