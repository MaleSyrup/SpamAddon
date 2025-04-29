--[[
    SpamAddonFeatures.lua
    Additional features and quality-of-life improvements for SpamAddon
    
    This file contains extra functionality beyond the core addon capabilities:
    - Minimap button for quick access
    - Localization system
    - Tooltips for UI elements
    - Sound effects for events
    - Visual indicators for active spam
    
    It enhances the user experience with helpful visual and audio feedback
    and makes the addon more accessible through additional interface options.
    
    Author: MaleSyrup
    Version: 1.0
]]--

local addonName, SpamAddon = ...

-- Create the features namespace
SpamAddon.Features = {}

-- LibDataBroker and LibDBIcon for minimap button
local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)

--[[
    Localization System
    Provides translation support for multiple languages.
    Currently only includes English, but structured to allow easy addition
    of more languages in the future.
]]--
local L = {}

-- English localization (default)
L["en"] = {
    -- General
    ["ADDON_LOADED"] = "SpamAddon v%s loaded.",
    ["ADDON_TOOLTIP"] = "SpamAddon\nClick: Toggle UI\nRight-click: Toggle spam",
    
    -- Status messages
    ["SPAM_STARTED"] = "Started spam timer - sending every %d seconds.",
    ["SPAM_STOPPED"] = "Stopped spam timer.",
    ["SPAM_PAUSED"] = "Spam paused. Will attempt to resume in 30 seconds.",
    ["SPAM_RESUMED"] = "Attempting to resume spam after pause.",
    ["STATUS_ACTIVE"] = "Status: |cFF00FF00Active|r",
    ["STATUS_INACTIVE"] = "Status: |cFFFF0000Inactive|r",
    
    -- Settings
    ["MESSAGE_SET"] = "Message set to: %s",
    ["CHANNEL_SET"] = "Channel set to: %s",
    ["WHISPER_TARGET_SET"] = "Whisper target set to: %s",
    ["INTERVAL_SET"] = "Interval set to: %d seconds",
    
    -- UI Elements
    ["MESSAGE_LABEL"] = "Message:",
    ["CHANNEL_LABEL"] = "Channel:",
    ["TARGET_LABEL"] = "Target:",
    ["INTERVAL_LABEL"] = "Interval (seconds):",
    ["START_BUTTON"] = "Start",
    ["STOP_BUTTON"] = "Stop",
    ["SECONDS"] = "%d seconds",
    
    -- Tooltips
    ["MESSAGE_TOOLTIP"] = "The text message to send to the selected channel",
    ["CHANNEL_TOOLTIP"] = "The chat channel where your message will be sent",
    ["TARGET_TOOLTIP"] = "Required for whispers: the character name to send whispers to",
    ["INTERVAL_TOOLTIP"] = "Time between messages (5-300 seconds)",
    ["START_TOOLTIP"] = "Start sending messages at regular intervals",
    ["STOP_TOOLTIP"] = "Stop sending messages",
    
    -- Error messages
    ["ERROR_EMPTY_MESSAGE"] = "Cannot send empty message.",
    ["ERROR_NO_WHISPER_TARGET"] = "No whisper target specified.",
    ["ERROR_INTERVAL_TOO_SHORT"] = "Interval too short, setting to 5 seconds.",
    ["ERROR_INVALID_CHANNEL"] = "Invalid channel: %s",
    ["ERROR_INVALID_CHANNEL_CONTEXT"] = "Cannot use channel %s in current context.",
    ["ERROR_PLAYER_OFFLINE"] = "Target player is offline. Spam paused.",
    ["ERROR_CHANNEL_UNAVAILABLE"] = "You can't send messages to %s. Spam paused.",
    ["ERROR_NO_PERMISSION"] = "You don't have permission to send messages to %s. Spam paused.",
    ["ERROR_TOO_MANY_ERRORS"] = "Too many errors (%d). Spam stopped.",
    ["ERROR_THROTTLED"] = "Message throttled to prevent disconnection.",
    ["ERROR_FAILED_TIMER"] = "Failed to create timer.",
    
    -- Warning messages
    ["WARNING_CHANNEL_MAY_BE_UNAVAILABLE"] = "Warning: Channel %s may not be available in current context.",
    ["WARNING_PLAYER_MAY_BE_OFFLINE"] = "Target player may not be online. Trying anyway.",
    
    -- Command help
    ["COMMAND_HELP_TITLE"] = "SpamAddon v%s Usage:",
    ["COMMAND_HELP_SHOW"] = "/spam show - Show the UI",
    ["COMMAND_HELP_HIDE"] = "/spam hide - Hide the UI",
    ["COMMAND_HELP_TOGGLE"] = "/spam toggle - Toggle spam on/off",
    ["COMMAND_HELP_START"] = "/spam start - Start spam timer",
    ["COMMAND_HELP_STOP"] = "/spam stop - Stop spam timer",
    ["COMMAND_HELP_MESSAGE"] = "/spam message <text> - Set the message",
    ["COMMAND_HELP_CHANNEL"] = "/spam channel <channel> - Set the channel",
    ["COMMAND_HELP_WHISPER"] = "/spam whisper <n> - Set whisper target",
    ["COMMAND_HELP_INTERVAL"] = "/spam interval <seconds> - Set timer interval (5+ seconds)",
    ["COMMAND_HELP_STATUS"] = "/spam status - Show current status",
    ["COMMAND_HELP_MINIMAP"] = "/spam minimap - Toggle minimap button",
    
    -- Status display
    ["STATUS_TITLE"] = "SpamAddon Status:",
    ["STATUS_ENABLED"] = "Enabled: %s",
    ["STATUS_MESSAGE"] = "Message: %s",
    ["STATUS_CHANNEL"] = "Channel: %s",
    ["STATUS_TARGET"] = "Target: %s",
    ["STATUS_INTERVAL"] = "Interval: %d seconds",
    ["STATUS_ERRORS"] = "Errors: %d",
    ["STATUS_LAST_ERROR"] = "Last Error: %s",
    ["STATUS_YES"] = "|cFF00FF00Yes|r",
    ["STATUS_NO"] = "|cFFFF0000No|r",
}

-- Set default locale
local locale = GetLocale() or "enUS"
if locale == "enUS" or locale == "enGB" then
    locale = "en"
end

-- If we don't have localization for the client language, use English
if not L[locale] then
    locale = "en"
end

--[[
    SpamAddon.L(key, ...)
    Gets a localized string for the given key, with optional formatting arguments
    
    Parameters:
    - key: The localization key to look up
    - ...: Optional format arguments for the string
    
    Returns:
    - Localized string, or the key itself if not found
]]--
function SpamAddon.L(key, ...)
    if not L[locale] or not L[locale][key] then
        return key
    end
    
    return string.format(L[locale][key], ...)
end

--[[
    SpamAddon.Features.SetupTooltips()
    Adds tooltips to all UI elements to improve usability
    This is called after the UI is created
]]--
function SpamAddon.Features.SetupTooltips()
    -- Message tooltip
    if messageEditBox then
        messageEditBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(SpamAddon.L("MESSAGE_TOOLTIP"))
            GameTooltip:Show()
        end)
        messageEditBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Channel dropdown tooltip
    if channelDropdown then
        channelDropdown:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(SpamAddon.L("CHANNEL_TOOLTIP"))
            GameTooltip:Show()
        end)
        channelDropdown:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Whisper target tooltip
    if whisperEditBox then
        whisperEditBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(SpamAddon.L("TARGET_TOOLTIP"))
            GameTooltip:Show()
        end)
        whisperEditBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Interval slider tooltip
    if intervalSlider then
        intervalSlider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(SpamAddon.L("INTERVAL_TOOLTIP"))
            GameTooltip:Show()
        end)
        intervalSlider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Start/Stop button tooltip
    if startStopButton then
        startStopButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            if SpamAddon.API.IsEnabled() then
                GameTooltip:SetText(SpamAddon.L("STOP_TOOLTIP"))
            else
                GameTooltip:SetText(SpamAddon.L("START_TOOLTIP"))
            end
            GameTooltip:Show()
        end)
        startStopButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

--[[
    SpamAddon.Features.InitMinimapButton()
    Creates a minimap button for quick access to the addon
    Uses LibDataBroker and LibDBIcon for implementation
]]--
function SpamAddon.Features.InitMinimapButton()
    -- Check if LibStub exists first
    local libsFound = true
    if not LibStub then
        print("|cFFFF9900SpamAddon: LibStub library not found. Minimap button disabled.|r")
        libsFound = false
    end
    
    -- Only try to get libraries if LibStub exists
    local LDB = libsFound and LibStub:GetLibrary("LibDataBroker-1.1", true) or nil
    local LibDBIcon = libsFound and LibStub:GetLibrary("LibDBIcon-1.0", true) or nil
    
    -- Check if both libraries were found
    if not LDB then
        print("|cFFFF9900SpamAddon: LibDataBroker-1.1 library not found. Minimap button disabled.|r")
        return
    end
    
    if not LibDBIcon then
        print("|cFFFF9900SpamAddon: LibDBIcon-1.0 library not found. Minimap button disabled.|r")
        return
    end
    
    -- Initialize saved variable for minimap button with error handling
    local success, errorMsg = pcall(function()
        -- Initialize saved variable for minimap button
        if not SpamAddonDB.minimap then
            SpamAddonDB.minimap = {
                hide = false
            }
        end
        
        -- Create the LDB launcher
        local minimapLauncher = LDB:NewDataObject("SpamAddon", {
            type = "launcher",
            text = "SpamAddon",
            icon = "Interface\\Icons\\INV_Letter_15",
            OnClick = function(self, button)
                if button == "LeftButton" then
                    if SpamAddon.UI and SpamAddon.UI.Toggle then
                        SpamAddon.UI.Toggle()
                    else
                        print("|cFFFF9900SpamAddon: UI not available yet.|r")
                    end
                elseif button == "RightButton" then
                    if SpamAddon.API and SpamAddon.API.ToggleSpam then
                        SpamAddon.API.ToggleSpam()
                    else
                        print("|cFFFF9900SpamAddon: API functionality not available yet.|r")
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then return end
                tooltip:AddLine(SpamAddon.L and SpamAddon.L("ADDON_TOOLTIP") or "SpamAddon\nClick: Toggle UI\nRight-click: Toggle spam")
            end,
        })
        
        -- Register with LibDBIcon
        LibDBIcon:Register("SpamAddon", minimapLauncher, SpamAddonDB.minimap)
    end)
    
    if not success then
        print("|cFFFF0000SpamAddon Error setting up minimap button: |r" .. tostring(errorMsg))
    else
        print("|cFF00FF00SpamAddon: Minimap button initialized.|r")
    end
end

-- Toggle minimap button visibility
function SpamAddon.Features.ToggleMinimapButton()
    -- Check if LibStub exists first
    if not LibStub then
        print("|cFFFF9900SpamAddon: LibStub library not found. Cannot toggle minimap button.|r")
        return
    end
    
    -- Try to get LibDBIcon
    local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
    
    -- Only toggle if we have the required library
    if not LibDBIcon then 
        print("|cFFFF9900SpamAddon: LibDBIcon-1.0 library not found. Cannot toggle minimap button.|r")
        return 
    end
    
    -- Check if we have initialized minimap settings
    if not SpamAddonDB.minimap then
        print("|cFFFF9900SpamAddon: Minimap settings not initialized. Initializing now.|r")
        SpamAddonDB.minimap = {
            hide = false
        }
    end
    
    local success, errorMsg = pcall(function()
        SpamAddonDB.minimap.hide = not SpamAddonDB.minimap.hide
        
        if SpamAddonDB.minimap.hide then
            LibDBIcon:Hide("SpamAddon")
            print("|cFFFF9900SpamAddon: Minimap button hidden.|r")
        else
            LibDBIcon:Show("SpamAddon")
            print("|cFF00FF00SpamAddon: Minimap button shown.|r")
        end
    end)
    
    if not success then
        print("|cFFFF0000SpamAddon Error toggling minimap button: |r" .. tostring(errorMsg))
    end
end

-- Play sound effect
function SpamAddon.Features.PlaySound(soundType)
    if not SpamAddonDB.soundEnabled then return end
    
    if soundType == "START" then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    elseif soundType == "STOP" then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    elseif soundType == "ERROR" then
        PlaySound(SOUNDKIT.IG_PLAYER_INVITE_DECLINE)
    end
end

-- Initialize additional features
function SpamAddon.Features.Init()
    -- Add slash commands with error handling
    local success, error = pcall(function()
        -- Add minimap toggle to slash commands
        if SpamAddon.RegisterExtraSlashCommand then
            SpamAddon.RegisterExtraSlashCommand("minimap", function()
                SpamAddon.Features.ToggleMinimapButton()
            end)
            
            -- Add sound toggle to slash commands
            SpamAddon.RegisterExtraSlashCommand("sound", function()
                SpamAddonDB.soundEnabled = not SpamAddonDB.soundEnabled
                if SpamAddonDB.soundEnabled then
                    print("|cFF00FF00SpamAddon: Sound effects enabled.|r")
                else
                    print("|cFFFF9900SpamAddon: Sound effects disabled.|r")
                end
            end)
        else
            print("|cFFFF9900SpamAddon: RegisterExtraSlashCommand not available. Additional slash commands disabled.|r")
        end
    end)
    
    if not success then
        print("|cFFFF0000SpamAddon Error registering extra slash commands: |r" .. tostring(error))
    end
    
    -- Initialize sound setting if not present
    if SpamAddonDB and SpamAddonDB.soundEnabled == nil then
        SpamAddonDB.soundEnabled = true
    end
    
    -- Setup the minimap button with error handling
    local buttonSuccess, buttonError = pcall(function()
        SpamAddon.Features.InitMinimapButton()
    end)
    
    if not buttonSuccess then
        print("|cFFFF0000SpamAddon Error initializing minimap button: |r" .. tostring(buttonError))
    end
end 