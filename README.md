# CmdTabType

A macOS app switcher replacement that lets you type to filter apps while holding Cmd+Tab.

**How it works:** Press Cmd+Tab to see all running apps. While still holding Cmd, type letters to fuzzy-filter the list. Release Cmd to switch to the selected app.

![demo](demo.gif)

---

## Installation

### Step 1: Build the App

# Clone the repo
git clone https://github.com/yourusername/CmdTabType.git
cd CmdTabType

# Build the app
xcodebuild -scheme CmdTabType -configuration Release -derivedDataPath build

# Copy to Applications
cp -r build/Build/Products/Release/CmdTabType.app /Applications/ Or open `CmdTabType.xcodeproj` in Xcode, press Cmd+B to build, then find the app in Products and drag it to Applications.

### Step 2: Grant Accessibility Permissions

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button
3. Navigate to `/Applications/CmdTabType.app` and add it
4. Make sure the toggle is **ON**

### Step 3: Disable the System App Switcher

Run this command in Terminal:

defaults write com.apple.Dock mcx-disabled -bool true && killall Dock### Step 4: Launch CmdTabType

Open `/Applications/CmdTabType.app`. You'll see a ⌘ icon in your menu bar.

---

## Usage

| Action | Keys |
|--------|------|
| Open switcher | Cmd + Tab |
| Cycle forward | Cmd + Tab (again) |
| Cycle backward | Cmd + Shift + Tab |
| Filter by name | Type letters while holding Cmd |
| Delete last character | Backspace |
| Cancel | Escape |
| Switch to selected app | Release Cmd |
| Click to select | Mouse click on any icon |

---

## Uninstall

### Re-enable the System App Switcher

defaults delete com.apple.Dock mcx-disabled && killall Dock### Remove the App

1. Quit CmdTabType from the menu bar
2. Delete `/Applications/CmdTabType.app`
3. Remove from Accessibility in System Settings

---

## Auto-Launch on Login (Optional)

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Select `CmdTabType.app`

---

## Troubleshooting

**Switcher doesn't appear:**
- Check that CmdTabType is running (⌘ icon in menu bar)
- Verify Accessibility permission is granted

**System app switcher still appears:**
- Make sure you ran the `defaults write` command
- The Dock should have restarted automatically

**App crashes:**
- Check Console.app for error messages
- Try removing and re-adding Accessibility permissions

---

## License

MIT
