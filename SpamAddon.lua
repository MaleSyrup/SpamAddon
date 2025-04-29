--[[
    SpamAddon.lua
    Core functionality for the SpamAddon
    
    This file contains the main logic for the SpamAddon which allows players to automate 
    sending text macros to chat channels at specified intervals.
    
    Features:
    - Automated message sending on configurable intervals
    - Support for all WoW chat channels
    - Error handling and automatic recovery
    - Integration with UI components
    - Sound notifications
    
    Author: MaleSyrup
    Version: 1.0
]]--

-- Create addon namespace
local addonName, SpamAddon = ...
SpamAddon.version = GetAddOnMetadata(addonName, "Version")

--[[
    Default settings for the addon
    These values are used when the addon is first loaded or when settings are reset
]]--
local defaults = {
    message = "This is a test message from SpamAddon!",
    channel = "SAY",
    interval = 60,
    enabled = false,
    whisperTarget = "",
    soundEnabled = true,
}

-- Variables
local timer = nil                    -- Timer object for recurring messages
local isLoaded = false               -- Flag to track if addon is fully loaded
local errorCount = 0                 -- Counter for consecutive errors
local lastError = nil                -- Last error type encountered
local maxConsecutiveErrors = 3       -- Maximum number of errors before stopping
local lastMessageTime = 0            -- Timestamp of last message sent
local throttleDelay = 1.5            -- Minimum seconds between messages to prevent throttling
local extraSlashCommands = {}        -- Storage for additional slash commands

-- Initialize frame for event handling
local eventFrame = CreateFrame("Frame")

-- Register for events that we need to handle
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")  -- For detecting errors

--[[
    Error messages to look for in system messages
    Maps error text patterns to error type identifiers
]]--
local errorMessages = {
    ["That player is not online"] = "PLAYER_OFFLINE",
    ["You are not in a party"] = "NOT_IN_PARTY",
    ["You are not in a raid"] = "NOT_IN_RAID",
    ["You are not in a guild"] = "NOT_IN_GUILD",
    ["You are not in the correct channel"] = "WRONG_CHANNEL",
    ["You don't have permission"] = "NO_PERMISSION"
}

--[[
    Event handler function
    Processes all registered events and routes them to appropriate functions
]]--
eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        SpamAddon:Initialize()
    elseif event == "PLAYER_LOGIN" then
        -- Delay UI creation until player is fully logged in
        C_Timer.After(1, function() 
            if isLoaded then
                SpamAddon:SetupUI()
                -- Initialize additional features after UI is created
                if SpamAddon.Features and SpamAddon.Features.Init then
                    SpamAddon.Features.Init()
                end
                -- Setup tooltips if available
                if SpamAddon.Features and SpamAddon.Features.SetupTooltips then
                    C_Timer.After(0.5, function()
                        SpamAddon.Features.SetupTooltips()
                    end)
                end
            end
        end)
    elseif event == "PLAYER_LOGOUT" then
        -- Make sure timer is canceled when logging out
        SpamAddon:StopSpam()
    elseif event == "CHAT_MSG_SYSTEM" then
        -- Check if the system message indicates an error with our messaging
        SpamAddon:CheckChatError(arg1)
    end
end)

--[[
    CheckChatError(message)
    Analyzes system messages to detect chat-related errors
    
    Parameters:
    - message: The system message to check
]]--
function SpamAddon:CheckChatError(message)
    if not timer then return end  -- Not sending spam, so ignore errors
    
    for pattern, errorType in pairs(errorMessages) do
        if message:find(pattern) then
            -- Found an error related to chat
            self:HandleChatError(errorType, message)
            return
        end
    end
end

--[[
    HandleChatError(errorType, message)
    Processes chat errors and takes appropriate action
    
    Parameters:
    - errorType: The type of error that occurred
    - message: The error message
]]--
function SpamAddon:HandleChatError(errorType, message)
    errorCount = errorCount + 1
    lastError = errorType
    
    -- Play error sound if enabled
    if SpamAddon.Features and SpamAddon.Features.PlaySound then
        SpamAddon.Features.PlaySound("ERROR")
    end
    
    -- Display error to user
    print("|cFFFF0000SpamAddon Error: |r" .. message)
    
    -- Handle different error types
    if errorType == "PLAYER_OFFLINE" and SpamAddonDB.channel == "WHISPER" then
        print("|cFFFF0000SpamAddon: Target player is offline. Spam paused.|r")
        self:PauseSpam()
    elseif (errorType == "NOT_IN_PARTY" and (SpamAddonDB.channel == "PARTY")) or
           (errorType == "NOT_IN_RAID" and (SpamAddonDB.channel == "RAID" or SpamAddonDB.channel == "RAID_WARNING")) or
           (errorType == "NOT_IN_GUILD" and (SpamAddonDB.channel == "GUILD" or SpamAddonDB.channel == "OFFICER")) then
        print("|cFFFF0000SpamAddon: You can't send messages to " .. SpamAddonDB.channel .. ". Spam paused.|r")
        self:PauseSpam()
    elseif errorType == "NO_PERMISSION" then
        print("|cFFFF0000SpamAddon: You don't have permission to send messages to " .. SpamAddonDB.channel .. ". Spam paused.|r")
        self:PauseSpam()
    elseif errorCount >= maxConsecutiveErrors then
        print("|cFFFF0000SpamAddon: Too many errors (" .. errorCount .. "). Spam stopped.|r")
        self:StopSpam()
    end
end

--[[
    PauseSpam()
    Temporarily pauses the spam timer and attempts to resume after a delay
]]--
function SpamAddon:PauseSpam()
    if timer then
        timer:Cancel()
        timer = nil
        
        -- Automatically try again after a delay
        C_Timer.After(30, function()
            if SpamAddonDB.enabled then
                print("|cFF00FF00SpamAddon: Attempting to resume spam after pause.|r")
                self:StartSpam()
            end
        end)
    end
end

--[[
    RegisterExtraSlashCommand(command, handler)
    Allows other modules to register additional slash commands
    
    Parameters:
    - command: The command name (without slash)
    - handler: The function to call when the command is used
]]--
function SpamAddon.RegisterExtraSlashCommand(command, handler)
    extraSlashCommands[command] = handler
end

--[[
    Initialize()
    Sets up the addon when it's first loaded
    - Initializes saved variables
    - Validates settings
    - Registers slash commands
    - Restores active state if needed
]]--
function SpamAddon:Initialize()
    -- Initialize saved variables
    if not SpamAddonDB then
        SpamAddonDB = CopyTable(defaults)
    end
    
    -- Check for missing values and update them
    for k, v in pairs(defaults) do
        if SpamAddonDB[k] == nil then
            SpamAddonDB[k] = v
        end
    end
    
    -- Validate saved settings
    self:ValidateSettings()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Restore active state if it was enabled
    if SpamAddonDB.enabled then
        C_Timer.After(5, function() 
            SpamAddon:StartSpam()
        end)
    end
    
    isLoaded = true
    local loadMsg = SpamAddon.L and SpamAddon.L("ADDON_LOADED", self.version) or
                    ("|cFF00FF00SpamAddon v" .. self.version .. " loaded.|r")
    print(loadMsg)
end

--[[
    ValidateSettings()
    Checks all saved settings for validity and applies corrections if needed
]]--
function SpamAddon:ValidateSettings()
    -- Validate message
    if not SpamAddonDB.message or SpamAddonDB.message == "" then
        SpamAddonDB.message = defaults.message
    end
    
    -- Validate channel
    if not self:IsValidChannel(SpamAddonDB.channel) then
        print("|cFFFF0000SpamAddon: Invalid saved channel. Resetting to SAY.|r")
        SpamAddonDB.channel = "SAY"
    end
    
    -- Validate interval
    if not SpamAddonDB.interval or SpamAddonDB.interval < 5 then
        print("|cFFFF0000SpamAddon: Invalid interval. Setting to minimum 5 seconds.|r")
        SpamAddonDB.interval = 5
    end
    
    -- Validate whisper target
    if SpamAddonDB.channel == "WHISPER" and (not SpamAddonDB.whisperTarget or SpamAddonDB.whisperTarget == "") then
        print("|cFFFF0000SpamAddon: Whisper channel selected but no target specified.|r")
        SpamAddonDB.whisperTarget = UnitName("player") -- Default to self as a fallback
    end
    
    -- Initialize sound setting if not present
    if SpamAddonDB.soundEnabled == nil then
        SpamAddonDB.soundEnabled = defaults.soundEnabled
    end
end

-- Check if a channel is valid
function SpamAddon:IsValidChannel(channel)
    local validChannels = {
        "SAY", "YELL", "PARTY", "RAID", "RAID_WARNING",
        "GUILD", "OFFICER", "WHISPER", "EMOTE", "INSTANCE_CHAT",
        "NUMBERED" -- Special type for handling numbered channels
    }
    
    -- Check standard channels
    for _, validChannel in ipairs(validChannels) do
        if channel == validChannel then
            return true
        end
    end
    
    -- Check if it's a numbered channel (format: NUMBER:X where X is 1-9)
    if channel:match("^NUMBER:%d+$") then
        local channelNum = tonumber(channel:match("NUMBER:(%d+)"))
        if channelNum and channelNum >= 1 and channelNum <= 9 then
            return true
        end
    end
    
    return false
end

-- Send message to chat
function SpamAddon:SendMessage()
    -- Reset error count if we've gone a while without errors
    if GetTime() - lastMessageTime > SpamAddonDB.interval * 2 then
        errorCount = 0
    end
    
    -- Check if we're throttled
    if GetTime() - lastMessageTime < throttleDelay then
        print("|cFFFF9900SpamAddon: Message throttled to prevent disconnection.|r")
        return false
    end
    
    -- Validate message
    if not SpamAddonDB.message or SpamAddonDB.message == "" then
        print("|cFFFF0000SpamAddon: Cannot send empty message.|r")
        return false
    end
    
    -- Handle whisper channel specially
    if SpamAddonDB.channel == "WHISPER" then
        if not SpamAddonDB.whisperTarget or SpamAddonDB.whisperTarget == "" then
            print("|cFFFF0000SpamAddon: No whisper target specified.|r")
            return false
        end
        
        -- Check if player exists in friends list or is nearby
        if not self:IsPlayerValid(SpamAddonDB.whisperTarget) then
            print("|cFFFF9900SpamAddon: Target player may not be online. Trying anyway.|r")
        end
        
        -- Try to send the message
        local success = pcall(function()
            SendChatMessage(SpamAddonDB.message, SpamAddonDB.channel, nil, SpamAddonDB.whisperTarget)
        end)
        
        if not success then
            print("|cFFFF0000SpamAddon: Error sending whisper to " .. SpamAddonDB.whisperTarget .. ".|r")
            errorCount = errorCount + 1
            return false
        end
    elseif SpamAddonDB.channel:match("^NUMBER:%d+$") then
        -- Handle numbered channels
        local channelNum = tonumber(SpamAddonDB.channel:match("NUMBER:(%d+)"))
        
        -- Try to send the message to the numbered channel
        local success = pcall(function()
            SendChatMessage(SpamAddonDB.message, "CHANNEL", nil, channelNum)
        end)
        
        if not success then
            print("|cFFFF0000SpamAddon: Error sending to channel " .. channelNum .. ".|r")
            errorCount = errorCount + 1
            return false
        end
    else
        -- For other channels, validate if the player is in the right context
        if not self:CanUseChannel(SpamAddonDB.channel) then
            print("|cFFFF0000SpamAddon: Cannot use channel " .. SpamAddonDB.channel .. " in current context.|r")
            errorCount = errorCount + 1
            self:PauseSpam()
            return false
        end
        
        -- Try to send the message
        local success = pcall(function()
            SendChatMessage(SpamAddonDB.message, SpamAddonDB.channel)
        end)
        
        if not success then
            print("|cFFFF0000SpamAddon: Error sending to " .. SpamAddonDB.channel .. ".|r")
            errorCount = errorCount + 1
            return false
        end
    end
    
    lastMessageTime = GetTime()
    errorCount = 0
    return true
end

-- Check if a player is valid (exists)
function SpamAddon:IsPlayerValid(playerName)
    -- Check if it's the player
    if playerName == UnitName("player") then
        return true
    end
    
    -- Check if they're in the player's group
    for i = 1, GetNumGroupMembers() do
        if playerName == UnitName("party" .. i) or playerName == UnitName("raid" .. i) then
            return true
        end
    end
    
    -- Check if they're a friend
    for i = 1, C_FriendList.GetNumFriends() do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name == playerName and info.connected then
            return true
        end
    end
    
    -- We don't know for sure if they're valid, but let's assume they might be
    return nil
end

-- Check if player can use a channel
function SpamAddon:CanUseChannel(channel)
    if channel == "SAY" or channel == "YELL" or channel == "EMOTE" then
        -- These are always available
        return true
    elseif channel == "PARTY" then
        return IsInGroup() and not IsInRaid()
    elseif channel == "RAID" or channel == "RAID_WARNING" then
        return IsInRaid()
    elseif channel == "GUILD" or channel == "OFFICER" then
        return IsInGuild()
    elseif channel == "INSTANCE_CHAT" then
        return IsInInstance()
    elseif channel:match("^NUMBER:%d+$") then
        -- Checking channel availability is complex, so we'll just return true
        -- and let the system handle any errors
        return true
    end
    
    -- Default to true for unknown channels
    return true
end

-- Start spam timer
function SpamAddon:StartSpam()
    -- Don't start if already running
    if timer then
        return
    end
    
    -- Validate interval
    local interval = SpamAddonDB.interval
    if interval < 5 then
        print("|cFFFF0000SpamAddon: Interval too short, setting to 5 seconds.|r")
        interval = 5
        SpamAddonDB.interval = interval
    end
    
    -- Reset error count when starting
    errorCount = 0
    lastError = nil
    
    -- Pre-check if the channel is valid in current context
    if not self:CanUseChannel(SpamAddonDB.channel) then
        print("|cFFFF9900SpamAddon: Warning - Channel " .. SpamAddonDB.channel .. " may not be available in current context.|r")
    end
    
    -- Create timer with protected call
    local success, newTimer = pcall(function()
        return C_Timer.NewTicker(interval, function()
            SpamAddon:SendMessage()
        end)
    end)
    
    if success and newTimer then
        timer = newTimer
        SpamAddonDB.enabled = true
        print("|cFF00FF00SpamAddon: Started spam timer - sending every " .. interval .. " seconds.|r")
        
        -- Play sound effect if enabled
        if SpamAddon.Features and SpamAddon.Features.PlaySound then
            SpamAddon.Features.PlaySound("START")
        end
        
        -- Notify UI if it exists
        if SpamAddon.UI and SpamAddon.UI.UpdateButton then
            SpamAddon.UI.UpdateButton()
        end
        
        if SpamAddon.UI and SpamAddon.UI.UpdateStatusText then
            SpamAddon.UI.UpdateStatusText()
        end
    else
        print("|cFFFF0000SpamAddon: Failed to create timer.|r")
    end
end

-- Stop spam timer
function SpamAddon:StopSpam()
    if timer then
        -- Use pcall to safely cancel the timer
        pcall(function() timer:Cancel() end)
        timer = nil
        SpamAddonDB.enabled = false
        print("|cFFFF0000SpamAddon: Stopped spam timer.|r")
        
        -- Play sound effect if enabled
        if SpamAddon.Features and SpamAddon.Features.PlaySound then
            SpamAddon.Features.PlaySound("STOP")
        end
        
        -- Notify UI if it exists
        if SpamAddon.UI and SpamAddon.UI.UpdateButton then
            SpamAddon.UI.UpdateButton()
        end
        
        if SpamAddon.UI and SpamAddon.UI.UpdateStatusText then
            SpamAddon.UI.UpdateStatusText()
        end
    end
end

-- Toggle spam timer
function SpamAddon:ToggleSpam()
    if timer then
        self:StopSpam()
    else
        self:StartSpam()
    end
end

-- Set message
function SpamAddon:SetMessage(message)
    if message and message ~= "" then
        SpamAddonDB.message = message
        print("|cFF00FF00SpamAddon: Message set to:|r " .. message)
        return true
    else
        print("|cFFFF0000SpamAddon: Cannot set empty message.|r")
        return false
    end
end

-- Set channel
function SpamAddon:SetChannel(channel)
    -- Handle special case for numbered channels (like /4)
    if channel:match("^%d+$") then
        local channelNum = tonumber(channel)
        if channelNum and channelNum >= 1 and channelNum <= 9 then
            SpamAddonDB.channel = "NUMBER:" .. channelNum
            print("|cFF00FF00SpamAddon: Channel set to:|r Channel " .. channelNum)
            
            -- If channel changed, restart timer if active
            if timer then
                self:StopSpam()
                self:StartSpam()
            end
            
            return true
        end
    end
    
    channel = string.upper(channel)
    local validChannels = {
        "SAY", "YELL", "PARTY", "RAID", "RAID_WARNING",
        "GUILD", "OFFICER", "WHISPER", "EMOTE", "INSTANCE_CHAT"
    }
    
    local isValid = false
    for _, validChannel in ipairs(validChannels) do
        if channel == validChannel then
            isValid = true
            break
        end
    end
    
    if isValid then
        -- Check if player can use this channel
        if not self:CanUseChannel(channel) then
            print("|cFFFF9900SpamAddon: Warning - Channel " .. channel .. " may not be available in current context.|r")
        end
        
        SpamAddonDB.channel = channel
        print("|cFF00FF00SpamAddon: Channel set to:|r " .. channel)
        
        -- If channel changed to/from WHISPER, restart timer if active
        if (channel == "WHISPER" or SpamAddonDB.channel == "WHISPER") and timer then
            self:StopSpam()
            self:StartSpam()
        end
        
        return true
    else
        print("|cFFFF0000SpamAddon: Invalid channel:|r " .. channel)
        print("|cFFFF0000Valid channels:|r SAY, YELL, PARTY, RAID, RAID_WARNING, GUILD, OFFICER, WHISPER, EMOTE, INSTANCE_CHAT, or a number 1-9")
        return false
    end
end

-- Set whisper target
function SpamAddon:SetWhisperTarget(target)
    if target and target ~= "" then
        SpamAddonDB.whisperTarget = target
        print("|cFF00FF00SpamAddon: Whisper target set to:|r " .. target)
        
        -- If already running in whisper mode, restart to use new target
        if timer and SpamAddonDB.channel == "WHISPER" then
            self:StopSpam()
            self:StartSpam()
        end
        
        return true
    else
        print("|cFFFF0000SpamAddon: Cannot set empty whisper target.|r")
        return false
    end
end

-- Set interval
function SpamAddon:SetInterval(interval)
    interval = tonumber(interval)
    if interval and interval >= 5 then
        SpamAddonDB.interval = interval
        print("|cFF00FF00SpamAddon: Interval set to:|r " .. interval .. " seconds")
        
        -- If timer is active, restart it with new interval
        if timer then
            self:StopSpam()
            self:StartSpam()
        end
        
        return true
    else
        print("|cFFFF0000SpamAddon: Invalid interval. Must be at least 5 seconds.|r")
        return false
    end
end

-- Show UI
function SpamAddon:ShowUI()
    if SpamAddon.UI and SpamAddon.UI.Show then
        SpamAddon.UI.Show()
        return true
    else
        print("|cFFFF0000SpamAddon: UI not available yet.|r")
        return false
    end
end

-- Hide UI
function SpamAddon:HideUI()
    if SpamAddon.UI and SpamAddon.UI.Hide then
        SpamAddon.UI.Hide()
        return true
    else
        print("|cFFFF0000SpamAddon: UI not available yet.|r")
        return false
    end
end

-- Toggle UI visibility
function SpamAddon:ToggleUI()
    if SpamAddon.UI and SpamAddon.UI.Toggle then
        SpamAddon.UI.Toggle()
        return true
    else
        print("|cFFFF0000SpamAddon: UI not available yet.|r")
        return false
    end
end

-- Register slash commands
function SpamAddon:RegisterSlashCommands()
    -- Register the slash command handler
    SLASH_SPAMADDON1 = "/spam"
    SlashCmdList["SPAMADDON"] = function(msg)
        local command, arg = strsplit(" ", msg, 2)
        command = command:lower()
        
        -- Process commands
        if command == "show" or command == "" then
            SpamAddon.UI.Show()
        elseif command == "hide" then
            SpamAddon.UI.Hide()
        elseif command == "toggle" then
            SpamAddon.API.ToggleSpam()
        elseif command == "start" then
            SpamAddon.API.StartSpam()
        elseif command == "stop" then
            SpamAddon.API.StopSpam()
        elseif command == "message" and arg then
            SpamAddon.API.SetMessage(arg)
            print("|cFF00FF00SpamAddon: Message set.|r")
        elseif command == "channel" and arg then
            SpamAddon.API.SetChannel(arg:upper())
            print("|cFF00FF00SpamAddon: Channel set to " .. arg:upper() .. ".|r")
        elseif command == "whisper" and arg then
            SpamAddon.API.SetWhisperTarget(arg)
            print("|cFF00FF00SpamAddon: Whisper target set to " .. arg .. ".|r")
        elseif command == "interval" and arg then
            local interval = tonumber(arg)
            if interval and interval >= 5 then
                SpamAddon.API.SetInterval(interval)
                print("|cFF00FF00SpamAddon: Interval set to " .. interval .. " seconds.|r")
            else
                print("|cFFFF0000SpamAddon: Invalid interval. Must be at least 5 seconds.|r")
            end
        elseif command == "status" then
            SpamAddon.API.PrintStatus()
        elseif command == "help" then
            -- Display help information
            print("|cFF00FF00SpamAddon v" .. SpamAddon.version .. " Help:|r")
            print("/spam show - Show the UI")
            print("/spam hide - Hide the UI")
            print("/spam toggle - Toggle spam on/off")
            print("/spam start - Start spam timer")
            print("/spam stop - Stop spam timer")
            print("/spam message <text> - Set the message")
            print("/spam channel <channel> - Set the channel")
            print("/spam whisper <name> - Set whisper target")
            print("/spam interval <seconds> - Set timer interval (5+ seconds)")
            print("/spam status - Show current status")
            print("/spam minimap - Toggle minimap button")
            print("/spam sound - Toggle sound effects")
            print("/spam help - Show this help message")
        else
            -- Check for extra slash commands
            local handled = false
            for cmd, handler in pairs(extraSlashCommands) do
                if command == cmd:lower() then
                    handler(arg)
                    handled = true
                    break
                end
            end
            
            if not handled then
                print("|cFFFF9900SpamAddon: Unknown command. Type '/spam help' for help.|r")
            end
        end
    end
end

-- Print help
function SpamAddon:PrintHelp()
    print("|cFF00FF00SpamAddon v" .. SpamAddon.version .. " Usage:|r")
    print("/spam show - Show the UI")
    print("/spam hide - Hide the UI")
    print("/spam toggle - Toggle UI visibility")
    print("/spam start - Start spam timer")
    print("/spam stop - Stop spam timer")
    print("/spam message <text> - Set the message")
    print("/spam channel <channel> - Set the channel")
    print("/spam whisper <name> - Set whisper target")
    print("/spam interval <seconds> - Set timer interval (5+ seconds)")
    print("/spam status - Show current status")
    
    -- Show any extra commands
    for cmd, _ in pairs(extraSlashCommands) do
        if cmd == "minimap" then
            print("/spam minimap - Toggle minimap button")
        elseif cmd == "sound" then
            print("/spam sound - Toggle sound effects")
        else
            print("/spam " .. cmd .. " - Custom command")
        end
    end
end

-- Print current status
function SpamAddon:PrintStatus()
    print("|cFF00FF00SpamAddon Status:|r")
    print("Enabled: " .. (SpamAddonDB.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("Message: " .. SpamAddonDB.message)
    print("Channel: " .. SpamAddonDB.channel)
    if SpamAddonDB.channel == "WHISPER" then
        print("Target: " .. SpamAddonDB.whisperTarget)
    end
    print("Interval: " .. SpamAddonDB.interval .. " seconds")
    print("Sound Effects: " .. (SpamAddonDB.soundEnabled and "|cFF00FF00Enabled|r" or "|cFFFF9900Disabled|r"))
    print("Errors: " .. errorCount)
    if lastError then
        print("Last Error: " .. lastError)
    end
end

-- Function to setup the UI (called from UI file)
function SpamAddon:SetupUI()
    if SpamAddon.UI and SpamAddon.UI.Create then
        SpamAddon.UI.Create()
    end
end

-- API for UI to access
SpamAddon.API = {
    GetMessage = function() return SpamAddonDB.message end,
    GetChannel = function() return SpamAddonDB.channel end,
    GetWhisperTarget = function() return SpamAddonDB.whisperTarget end,
    GetInterval = function() return SpamAddonDB.interval end,
    IsEnabled = function() return SpamAddonDB.enabled end,
    IsSoundEnabled = function() return SpamAddonDB.soundEnabled end,
    
    SetMessage = function(msg) return SpamAddon:SetMessage(msg) end,
    SetChannel = function(channel) return SpamAddon:SetChannel(channel) end,
    SetWhisperTarget = function(target) return SpamAddon:SetWhisperTarget(target) end,
    SetInterval = function(interval) return SpamAddon:SetInterval(interval) end,
    
    StartSpam = function() SpamAddon:StartSpam() end,
    StopSpam = function() SpamAddon:StopSpam() end,
    ToggleSpam = function() SpamAddon:ToggleSpam() end,
    
    GetSavedVariables = function() return SpamAddonDB end
} 