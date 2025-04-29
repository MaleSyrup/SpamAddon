# SpamAddon

## Overview

SpamAddon is a World of Warcraft addon that allows players to automate sending text macros to chat channels at specified intervals. It provides a simple and intuitive interface for configuring message content, destination channels, and timing, with additional quality-of-life features like a minimap button and visual indicators.

## Features

- **Automated Message Sending**: Send predefined messages to any chat channel automatically.
- **Customizable Intervals**: Set the timing between messages (from 30 seconds to any duration).
- **Channel Selection**: Choose from all available WoW chat channels, including numbered channels (General, Trade, LocalDefense, Services, etc.).
- **Message Management**: Create, edit, and delete multiple message templates.
- **Minimap Button**: Quick access to the addon through a convenient minimap icon.
- **Visual Indicators**: Clear visual feedback when spam is active.
- **Command-Line Interface**: Control the addon through chat commands.
- **Help System**: Built-in help and documentation.

## Installation

1. Download the latest release of SpamAddon from the [releases page](https://github.com/MaleSyrup/SpamAddon/releases).
2. Extract the ZIP file contents to your World of Warcraft addon directory:
   - Retail WoW: `World of Warcraft\_retail_\Interface\AddOns\`
   - Classic WoW: `World of Warcraft\_classic_\Interface\AddOns\`
3. **IMPORTANT**: Ensure the folder structure is correct:
   - The path should be: `Interface\AddOns\SpamAddon\SpamAddon.toc`
   - Make sure the folder name is exactly "SpamAddon" (not "SpamAddon-main" or "SpamAddon-1.0")
4. Verify all required libraries are present in the Libs folder:
   - LibStub
   - CallbackHandler-1.0
   - LibDataBroker-1.1
   - LibDBIcon-1.0
5. Restart World of Warcraft or reload your UI (`/reload`).
6. The addon should appear in your addon list and be enabled by default.

### Troubleshooting Installation

If the addon is not working properly after installation:

1. **Check folder structure**: Use `/run print(IsAddOnLoaded("SpamAddon"))` in-game. If it returns "false", the addon folder structure is incorrect.
2. **Verify libraries**: Ensure all libraries in the Libs folder were extracted properly.
3. **Check error messages**: Type `/dump _G.SpamAddon` to check if the addon loaded at all.
4. **Disable conflicting addons**: Some addons might conflict with SpamAddon's functionality.

## Usage

### Basic Commands

- `/spam` or `/spamaddon` - Opens the main SpamAddon interface
- `/spam help` - Displays available commands and usage instructions
- `/spam toggle` - Toggles spam messages on/off
- `/spam config` - Opens the configuration panel

### Setting Up a Spam Message

1. Open the SpamAddon interface with `/spam`.
2. Enter your message in the text field.
3. Select the desired chat channel from the dropdown menu:
   - Standard channels: SAY, YELL, PARTY, etc.
   - Numbered channels: Select from the "Numbered Channels" submenu (includes General, Trade, Services, etc.)
   - Custom channel number: Choose "Other Channel Number..." to enter a specific channel number
4. Set the interval (in seconds) using the slider.
5. Click "Save" to store your message.
6. Click "Start" to begin sending your message at the specified interval.

### Using the Minimap Button

- Left-click to open the main interface.
- Right-click to toggle spam on/off.
- Shift+right-click to open the configuration panel.

## Configuration Options

- **Enable/Disable**: Toggle the addon on or off.
- **Show Minimap Button**: Show or hide the minimap icon.
- **Visual Indicator**: Toggle the visual indicator when spam is active.
- **Sound Effects**: Enable or disable sound notifications.
- **Interval Limits**: Set minimum and maximum interval limits.
- **Chat Channels**: Configure available chat channels.

## Troubleshooting

- **Messages not sending**: Ensure you have appropriate permissions for the selected channel.
- **Addon not appearing**: Verify the addon is enabled in the character's addon list.
- **Interval issues**: Check if you've set a reasonable interval (too short intervals may be throttled by the game).

## Frequently Asked Questions

1. **Will I get banned for using this addon?**

   - Using this addon responsibly should not lead to a ban. However, excessive spamming in public channels may violate Blizzard's terms of service. Use wisely and considerately.

2. **Can I use this for trade advertisements?**

   - Yes, but be mindful of frequency. Set reasonable intervals (5+ minutes) for trade channel messages.

3. **Does this work in Classic WoW?**
   - This version is designed for retail WoW. A Classic version may be available separately.

## Known Issues

- Message throttling may occur if intervals are set too low.
- Some special characters may not display correctly in all chat channels.

## Version History

- **1.0**: Initial release with core functionality and UI.

## Credits

- Created by MaleSyrup
- Icon artwork adapted from Blizzard resources
- Libraries: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0

## License

SpamAddon is released under the MIT License. See the LICENSE file for details.

## Feedback and Support

For bug reports, feature requests, or general feedback, please open an issue on the [GitHub repository](https://github.com/MaleSyrup/SpamAddon) or contact the author in-game.

## Command-Line Examples

- `/spam channel 4` - Set the channel to the Services channel (channel 4)
- `/spam channel GUILD` - Set the channel to Guild chat
- `/spam message WTS [Item Link] - PST for details!` - Set your trade message
- `/spam interval 300` - Set spam interval to 5 minutes (recommended for trade)
