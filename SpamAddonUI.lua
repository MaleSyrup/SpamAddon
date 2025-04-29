--[[
    SpamAddonUI.lua
    User interface components for SpamAddon
    
    This file contains all the UI elements and handlers for the SpamAddon interface.
    It creates a movable frame with controls for configuring and managing spam messages.
    
    UI Components:
    - Main frame with draggable header
    - Message input field
    - Channel selection dropdown
    - Whisper target input (when applicable)
    - Interval slider
    - Start/Stop button
    - Status display
    - Error message display
    
    Author: MaleSyrup
    Version: 1.0
]]--

local addonName, SpamAddon = ...

-- Create UI namespace
SpamAddon.UI = {}

-- UI Elements
local mainFrame
local messageEditBox
local channelDropdown
local whisperEditBox
local intervalSlider
local startStopButton
local statusText
local errorText

-- Constants
local FRAME_WIDTH = 350
local FRAME_HEIGHT = 270  -- Increased height for error message
local HEADER_HEIGHT = 20
local ELEMENT_HEIGHT = 24
local SPACING = 10
local INSET = 12

-- Colors
local HEADER_COLOR = {r=0.4, g=0.4, b=0.8, a=1}
local BG_COLOR = {r=0.1, g=0.1, b=0.1, a=0.9}
local BORDER_COLOR = {r=0.5, g=0.5, b=0.5, a=1}
local ACTIVE_COLOR = {r=0, g=1, b=0, a=1}
local INACTIVE_COLOR = {r=1, g=0, b=0, a=1}
local WARNING_COLOR = {r=1, g=0.6, b=0, a=1}

-- Channel list for dropdown
local channelList = {
    "SAY", "YELL", "PARTY", "RAID", "RAID_WARNING",
    "GUILD", "OFFICER", "WHISPER", "EMOTE", "INSTANCE_CHAT"
}

-- Numbered channel list
local numberedChannels = {
    {id = 1, name = "General"},
    {id = 2, name = "Trade"},
    {id = 3, name = "LocalDefense"},
    {id = 4, name = "Services"}
    -- Add other common numbered channels as needed
}

--[[
    CreateBackdrop(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    Helper function to create a backdrop with background and border
    
    Parameters:
    - frame: The frame to apply the backdrop to
    - bgR, bgG, bgB, bgA: Background color (RGBA)
    - borderR, borderG, borderB, borderA: Border color (RGBA)
]]--
local function CreateBackdrop(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(bgR, bgG, bgB, bgA)
    
    frame.border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame.border:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
end

--[[
    ValidateInput(inputType, value)
    Validates user input and displays appropriate error messages
    
    Parameters:
    - inputType: Type of input to validate ("message", "whisperTarget", "interval")
    - value: The value to validate
    
    Returns:
    - isValid: Boolean indicating if the input is valid
]]--
local function ValidateInput(inputType, value)
    local isValid = true
    local errorMsg = nil
    
    -- Different validation for different input types
    if inputType == "message" then
        if not value or value == "" then
            isValid = false
            errorMsg = "Message cannot be empty"
        elseif string.len(value) > 255 then
            isValid = false
            errorMsg = "Message is too long (max 255 characters)"
        end
    elseif inputType == "whisperTarget" then
        if SpamAddon.API.GetChannel() == "WHISPER" and (not value or value == "") then
            isValid = false
            errorMsg = "Whisper target is required"
        end
    elseif inputType == "interval" then
        local numVal = tonumber(value)
        if not numVal then
            isValid = false
            errorMsg = "Interval must be a number"
        elseif numVal < 5 then
            isValid = false
            errorMsg = "Interval must be at least 5 seconds"
        elseif numVal > 300 then
            isValid = false
            errorMsg = "Interval must be at most 300 seconds"
        end
    end
    
    -- Update error display if we have an error text element
    if errorText then
        if not isValid and errorMsg then
            errorText:SetText("|cFFFF0000Error: " .. errorMsg .. "|r")
            errorText:Show()
        else
            errorText:Hide()
        end
    end
    
    return isValid
end

--[[
    SpamAddon.UI.Create()
    Creates the main UI frame and all child elements
    This is the main function for building the interface
]]--
function SpamAddon.UI.Create()
    -- Main Frame
    mainFrame = CreateFrame("Frame", "SpamAddonFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)
    
    -- Set backdrop
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8}
    })
    mainFrame:SetBackdropColor(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a)
    mainFrame:SetBackdropBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b, BORDER_COLOR.a)
    
    -- Header
    local header = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    header:SetText("SpamAddon")
    
    -- Close Button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() SpamAddon.UI.Hide() end)
    
    -- Message Label
    local messageLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", INSET, -(INSET + HEADER_HEIGHT + SPACING))
    messageLabel:SetText("Message:")
    
    -- Message EditBox
    messageEditBox = CreateFrame("EditBox", nil, mainFrame, BackdropTemplateMixin and "BackdropTemplate")
    messageEditBox:SetPoint("TOPLEFT", messageLabel, "BOTTOMLEFT", 0, -5)
    messageEditBox:SetPoint("RIGHT", mainFrame, "RIGHT", -INSET, 0)
    messageEditBox:SetHeight(ELEMENT_HEIGHT)
    messageEditBox:SetFontObject("ChatFontNormal")
    messageEditBox:SetAutoFocus(false)
    messageEditBox:SetMaxLetters(255)
    messageEditBox:SetMultiLine(false)
    messageEditBox:SetScript("OnEnterPressed", function(self)
        if ValidateInput("message", self:GetText()) then
            SpamAddon.API.SetMessage(self:GetText())
            self:ClearFocus()
        end
    end)
    messageEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(SpamAddon.API.GetMessage())
        self:ClearFocus()
    end)
    -- Add validation on text change
    messageEditBox:SetScript("OnTextChanged", function(self)
        ValidateInput("message", self:GetText())
    end)
    CreateBackdrop(messageEditBox, 0, 0, 0, 1, 0.3, 0.3, 0.3, 1)
    
    -- Channel Label
    local channelLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", messageEditBox, "BOTTOMLEFT", 0, -SPACING)
    channelLabel:SetText("Channel:")
    
    -- Channel Dropdown
    local channelDropdownAnchor = CreateFrame("Frame", nil, mainFrame)
    channelDropdownAnchor:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", -15, -2)
    channelDropdownAnchor:SetSize(120, 32)
    
    channelDropdown = CreateFrame("Frame", "SpamAddonChannelDropdown", channelDropdownAnchor, "UIDropDownMenuTemplate")
    
    -- Initialize the dropdown menu
    UIDropDownMenu_Initialize(channelDropdown, function(self, level)
        -- First level menu
        if level == 1 then
            -- Standard channels
            for _, channelName in ipairs(channelList) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = channelName
                info.value = channelName
                info.checked = (SpamAddon.API.GetChannel() == channelName)
                -- Add validation for PARTY, RAID, GUILD
                local isAvailable = true
                if channelName == "PARTY" and not IsInGroup() then
                    info.text = channelName .. " |cFFFF9900(Not in party)|r"
                    isAvailable = false
                elseif (channelName == "RAID" or channelName == "RAID_WARNING") and not IsInRaid() then
                    info.text = channelName .. " |cFFFF9900(Not in raid)|r"
                    isAvailable = false
                elseif (channelName == "GUILD" or channelName == "OFFICER") and not IsInGuild() then
                    info.text = channelName .. " |cFFFF9900(Not in guild)|r"
                    isAvailable = false
                end
                
                info.func = function(self)
                    SpamAddon.API.SetChannel(self.value)
                    UIDropDownMenu_SetText(channelDropdown, self.value)
                    -- Show/hide whisper target field based on channel selection
                    if self.value == "WHISPER" then
                        whisperEditBox:Show()
                        ValidateInput("whisperTarget", whisperEditBox:GetText())
                    else
                        whisperEditBox:Hide()
                        if errorText then
                            errorText:Hide()
                        end
                    end
                    
                    -- Show warning if channel not available
                    if not isAvailable then
                        SpamAddon.UI.ShowError("Warning: " .. channelName .. " channel may not be available")
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            
            -- Add numbered channels sub-menu
            local numberedInfo = UIDropDownMenu_CreateInfo()
            numberedInfo.text = "Numbered Channels"
            numberedInfo.hasArrow = true
            numberedInfo.notCheckable = true
            numberedInfo.value = "NUMBERED_CHANNELS"
            UIDropDownMenu_AddButton(numberedInfo, level)
            
            -- Also check if current channel is a numbered channel
            if SpamAddon.API.GetChannel():match("^NUMBER:%d+$") then
                local channelNum = tonumber(SpamAddon.API.GetChannel():match("NUMBER:(%d+)"))
                local currentMenu = UIDropDownMenu_CreateInfo()
                currentMenu.text = "Current: Channel " .. channelNum
                currentMenu.notCheckable = true
                currentMenu.isTitle = true
                UIDropDownMenu_AddButton(currentMenu, level)
            end
        -- Second level menu (numbered channels)
        elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "NUMBERED_CHANNELS" then
            -- Add common numbered channels
            for _, channel in ipairs(numberedChannels) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = channel.id .. ": " .. channel.name
                info.value = channel.id
                info.checked = (SpamAddon.API.GetChannel() == "NUMBER:" .. channel.id)
                info.func = function(self)
                    SpamAddon.API.SetChannel(tostring(self.value))
                    UIDropDownMenu_SetText(channelDropdown, "Channel " .. self.value)
                    whisperEditBox:Hide()
                    if errorText then
                        errorText:Hide()
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            
            -- Add custom channel number input
            local customInfo = UIDropDownMenu_CreateInfo()
            customInfo.text = "Other Channel Number..."
            customInfo.notCheckable = true
            customInfo.func = function()
                -- Close the dropdown
                CloseDropDownMenus()
                
                -- Ask for channel number via StaticPopup
                StaticPopupDialogs["SPAMADDON_CHANNEL_NUMBER"] = {
                    text = "Enter channel number (1-9):",
                    button1 = "OK",
                    button2 = "Cancel",
                    hasEditBox = true,
                    maxLetters = 1,
                    OnAccept = function(self)
                        local channelNum = self.editBox:GetText()
                        if channelNum:match("^%d$") and tonumber(channelNum) >= 1 and tonumber(channelNum) <= 9 then
                            SpamAddon.API.SetChannel(channelNum)
                            UIDropDownMenu_SetText(channelDropdown, "Channel " .. channelNum)
                        else
                            SpamAddon.UI.ShowError("Invalid channel number. Must be 1-9.")
                        end
                    end,
                    OnShow = function(self)
                        self.editBox:SetFocus()
                    end,
                    OnCancel = function() end,
                    EditBoxOnEnterPressed = function(self)
                        local parent = self:GetParent()
                        local channelNum = parent.editBox:GetText()
                        if channelNum:match("^%d$") and tonumber(channelNum) >= 1 and tonumber(channelNum) <= 9 then
                            SpamAddon.API.SetChannel(channelNum)
                            UIDropDownMenu_SetText(channelDropdown, "Channel " .. channelNum)
                            parent:Hide()
                        else
                            SpamAddon.UI.ShowError("Invalid channel number. Must be 1-9.")
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("SPAMADDON_CHANNEL_NUMBER")
            end
            UIDropDownMenu_AddButton(customInfo, level)
        end
    end)
    UIDropDownMenu_SetWidth(channelDropdown, 120)
    UIDropDownMenu_SetButtonWidth(channelDropdown, 124)
    UIDropDownMenu_JustifyText(channelDropdown, "LEFT")
    
    -- Set the appropriate dropdown text based on the current channel
    if SpamAddon.API.GetChannel():match("^NUMBER:%d+$") then
        local channelNum = tonumber(SpamAddon.API.GetChannel():match("NUMBER:(%d+)"))
        UIDropDownMenu_SetText(channelDropdown, "Channel " .. channelNum)
    else
        UIDropDownMenu_SetText(channelDropdown, SpamAddon.API.GetChannel())
    end
    
    -- Whisper Target Label
    local whisperLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whisperLabel:SetPoint("TOPLEFT", channelDropdownAnchor, "TOPRIGHT", 10, 0)
    whisperLabel:SetText("Target:")
    
    -- Whisper Target EditBox
    whisperEditBox = CreateFrame("EditBox", nil, mainFrame, BackdropTemplateMixin and "BackdropTemplate")
    whisperEditBox:SetPoint("TOPLEFT", whisperLabel, "BOTTOMLEFT", 0, -5)
    whisperEditBox:SetPoint("RIGHT", mainFrame, "RIGHT", -INSET, 0)
    whisperEditBox:SetHeight(ELEMENT_HEIGHT)
    whisperEditBox:SetFontObject("ChatFontNormal")
    whisperEditBox:SetAutoFocus(false)
    whisperEditBox:SetMaxLetters(32)
    whisperEditBox:SetMultiLine(false)
    whisperEditBox:SetScript("OnEnterPressed", function(self)
        if ValidateInput("whisperTarget", self:GetText()) then
            SpamAddon.API.SetWhisperTarget(self:GetText())
            self:ClearFocus()
        end
    end)
    whisperEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(SpamAddon.API.GetWhisperTarget())
        self:ClearFocus()
    end)
    -- Add validation on text change
    whisperEditBox:SetScript("OnTextChanged", function(self)
        if SpamAddon.API.GetChannel() == "WHISPER" then
            ValidateInput("whisperTarget", self:GetText())
        end
    end)
    CreateBackdrop(whisperEditBox, 0, 0, 0, 1, 0.3, 0.3, 0.3, 1)
    
    -- Show/hide based on current channel
    if SpamAddon.API.GetChannel() == "WHISPER" then
        whisperEditBox:Show()
    else
        whisperEditBox:Hide()
    end
    
    -- Interval Label
    local intervalLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intervalLabel:SetPoint("TOPLEFT", channelDropdownAnchor, "BOTTOMLEFT", 15, -SPACING)
    intervalLabel:SetText("Interval (seconds):")
    
    -- Interval Slider
    intervalSlider = CreateFrame("Slider", "SpamAddonIntervalSlider", mainFrame, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 0, -5)
    intervalSlider:SetWidth(200)
    intervalSlider:SetMinMaxValues(5, 300)
    intervalSlider:SetValueStep(1)
    intervalSlider:SetObeyStepOnDrag(true)
    intervalSlider:SetValue(SpamAddon.API.GetInterval())
    intervalSlider.Text:SetText(SpamAddon.API.GetInterval() .. " seconds")
    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.Text:SetText(value .. " seconds")
        
        -- Only update if done dragging to prevent constant updates
        if not self.isSliding then
            if ValidateInput("interval", value) then
                SpamAddon.API.SetInterval(value)
            end
        end
    end)
    intervalSlider:SetScript("OnMouseDown", function(self)
        self.isSliding = true
    end)
    intervalSlider:SetScript("OnMouseUp", function(self)
        self.isSliding = false
        local value = math.floor(self:GetValue())
        if ValidateInput("interval", value) then
            SpamAddon.API.SetInterval(value)
        end
    end)
    
    -- Error text display
    errorText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    errorText:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, INSET + 60)
    errorText:SetWidth(FRAME_WIDTH - 2*INSET)
    errorText:SetJustifyH("CENTER")
    errorText:Hide()
    
    -- Start/Stop Button
    startStopButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    startStopButton:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, INSET + 5)
    startStopButton:SetSize(120, 25)
    startStopButton:SetText(SpamAddon.API.IsEnabled() and "Stop" or "Start")
    startStopButton:SetScript("OnClick", function()
        -- Validate all required fields before starting
        if not SpamAddon.API.IsEnabled() then
            -- Only check when starting
            local canStart = true
            
            -- Validate message
            if not ValidateInput("message", SpamAddon.API.GetMessage()) then
                canStart = false
            end
            
            -- Validate whisper target if needed
            if SpamAddon.API.GetChannel() == "WHISPER" then
                if not ValidateInput("whisperTarget", SpamAddon.API.GetWhisperTarget()) then
                    canStart = false
                end
            end
            
            -- Validate interval
            if not ValidateInput("interval", SpamAddon.API.GetInterval()) then
                canStart = false
            end
            
            if not canStart then
                return
            end
        end
        
        SpamAddon.API.ToggleSpam()
        SpamAddon.UI.UpdateButton()
    end)
    
    -- Status text
    statusText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("BOTTOM", startStopButton, "TOP", 0, 5)
    SpamAddon.UI.UpdateStatusText()
    
    -- Initial setup
    SpamAddon.UI.UpdateFromSavedVars()
    
    -- Show the frame
    mainFrame:Show()
end

-- Show an error message
function SpamAddon.UI.ShowError(message, isWarning)
    if not errorText then return end
    
    if isWarning then
        errorText:SetText("|cFFFF9900Warning: " .. message .. "|r")
    else
        errorText:SetText("|cFFFF0000Error: " .. message .. "|r")
    end
    
    errorText:Show()
    
    -- Hide after 5 seconds
    C_Timer.After(5, function()
        if errorText:IsShown() and errorText:GetText():find(message) then
            errorText:Hide()
        end
    end)
end

-- Update the UI elements from saved variables
function SpamAddon.UI.UpdateFromSavedVars()
    if not mainFrame then return end
    
    messageEditBox:SetText(SpamAddon.API.GetMessage())
    UIDropDownMenu_SetText(channelDropdown, SpamAddon.API.GetChannel())
    whisperEditBox:SetText(SpamAddon.API.GetWhisperTarget())
    intervalSlider:SetValue(SpamAddon.API.GetInterval())
    
    if SpamAddon.API.GetChannel() == "WHISPER" then
        whisperEditBox:Show()
        ValidateInput("whisperTarget", SpamAddon.API.GetWhisperTarget())
    else
        whisperEditBox:Hide()
    end
    
    SpamAddon.UI.UpdateButton()
    SpamAddon.UI.UpdateStatusText()
    
    -- Validate current settings when updating
    ValidateInput("message", SpamAddon.API.GetMessage())
    ValidateInput("interval", SpamAddon.API.GetInterval())
end

-- Update the start/stop button
function SpamAddon.UI.UpdateButton()
    if not startStopButton then return end
    
    if SpamAddon.API.IsEnabled() then
        startStopButton:SetText("Stop")
        -- Change button color to indicate active state
        startStopButton:SetNormalFontObject("GameFontHighlight")
    else
        startStopButton:SetText("Start")
        -- Reset button color
        startStopButton:SetNormalFontObject("GameFontNormal")
    end
end

-- Update status text
function SpamAddon.UI.UpdateStatusText()
    if not statusText then return end
    
    if SpamAddon.API.IsEnabled() then
        statusText:SetText("Status: |cFF00FF00Active|r")
        
        -- Create a pulsing animation for the status text
        if not statusText.pulseAnimation then
            statusText.pulseAnimation = statusText:CreateAnimationGroup()
            statusText.pulseAnimation:SetLooping("REPEAT")
            
            local fadeOut = statusText.pulseAnimation:CreateAnimation("Alpha")
            fadeOut:SetFromAlpha(1.0)
            fadeOut:SetToAlpha(0.5)
            fadeOut:SetDuration(0.8)
            fadeOut:SetOrder(1)
            
            local fadeIn = statusText.pulseAnimation:CreateAnimation("Alpha")
            fadeIn:SetFromAlpha(0.5)
            fadeIn:SetToAlpha(1.0)
            fadeIn:SetDuration(0.8)
            fadeIn:SetOrder(2)
        end
        
        -- Start the animation
        statusText.pulseAnimation:Play()
    else
        statusText:SetText("Status: |cFFFF0000Inactive|r")
        
        -- Stop the animation if it exists
        if statusText.pulseAnimation then
            statusText.pulseAnimation:Stop()
        end
        
        -- Reset the alpha
        statusText:SetAlpha(1.0)
    end
end

-- Show UI
function SpamAddon.UI.Show()
    if not mainFrame then
        SpamAddon.UI.Create()
    else
        SpamAddon.UI.UpdateFromSavedVars()
        mainFrame:Show()
    end
end

-- Hide UI
function SpamAddon.UI.Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Toggle UI visibility
function SpamAddon.UI.Toggle()
    if mainFrame and mainFrame:IsShown() then
        SpamAddon.UI.Hide()
    else
        SpamAddon.UI.Show()
    end
end 