# Notionist Widget

Open-source macOS desktop widget that lists upcoming rows from a Notion database. Supported columns are **Name** (title), optional **Date** (date), and optional **Status** (select). The widget refreshes from Notion every 30 minutes.

---

## Install

This project is distributed as source only. There is no prebuilt `.app`.

The widget is configured before build time through a bundled JSON file, so it does not depend on App Groups or runtime settings sharing between the app and widget.

The Xcode project is already configured to use local ad hoc signing, shown by Xcode as **Sign to Run Locally**. You do not need to add an Apple Developer team for the default local build flow.

---

## Build from Source

### Step 0 — Clone the repository

```zsh
git clone https://github.com/kingtochan/NotionistWidget.git
cd NotionistWidget
```

### Prerequisites

- macOS 13 or later
- Xcode 15 or later

### Step 1 — Prepare your Notion integration

1. Create an [integration](https://www.notion.so/my-integrations) and copy its secret token.
2. Open your Notion database, click **…** → **Connections**, and share it with your integration.
3. Find the database ID in the URL. It is the string between the last `/` and the `?`.

### Step 2 — Edit the widget config

Open `Config/widget-config.json` and fill in your values before building:

```json
{
  "notion": {
    "token": "YOUR_NOTION_TOKEN_HERE",
    "databaseId": "YOUR_DATABASE_ID_HERE",
    "apiVersion": "2022-06-28"
  },
  "widget": {
    "title": "Notionist Widget",
    "backgroundColor": "darkGray",
    "textColor": "white",
    "maxItemsMedium": 4,
    "maxItemsLarge": 8,
    "listStyle": "bullet"
  }
}
```

### Step 3 — Build and run

1. Open `NotionistWidget.xcodeproj` in Xcode.
2. Leave the signing settings as they are. The project is already set up for local **Sign to Run Locally** signing.
3. Select the **NotionistWidgetApp** scheme and **My Mac** as the destination.
4. **Product** → **Build** once from Xcode.
5. In Xcode, choose **Product** → **Show Build Folder in Finder**.
6. Move `NotionistWidgetApp.app` to `/Applications`.
7. Launch the app once from `/Applications`.
8. Right-click your desktop → **Edit Widgets** → search **Notionist** → add the widget.

If you change `widget-config.json`, rebuild the app so the updated config is bundled into the widget.

### Optional — Command line verification build

```zsh
xcodebuild \
  -project NotionistWidget.xcodeproj \
  -scheme NotionistWidgetApp \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This command is mainly useful to verify that the project compiles. For actual widget installation and discovery in **Edit Widgets**, use the Xcode-built app from the steps above.

---

## How It Works

- `NotionistWidgetApp` is a lightweight container app for the widget.
- `WidgetExtension` reads settings from the bundled `Config/widget-config.json` file.
- To change credentials or display options, edit the JSON file and rebuild.

---

## Configuration Reference

| Key | Description |
|---|---|
| `notion.token` | Your Notion integration secret, usually starting with `ntn_` |
| `notion.databaseId` | Database ID from the Notion URL |
| `notion.apiVersion` | Notion API version header, for example `2022-06-28` |
| `widget.title` | Any text shown as the widget header |
| `widget.backgroundColor` | A supported color name or a hex code |
| `widget.textColor` | A supported color name or a hex code |
| `widget.maxItemsMedium` | Whole number of rows to show on a medium widget |
| `widget.maxItemsLarge` | Whole number of rows to show on a large widget |
| `widget.listStyle` | `bullet` or `numbered` |

### Parameter options

#### `notion.token`

- Use your Notion integration secret.
- Example: `ntn_xxxxxxxxxxxx`

#### `notion.databaseId`

- Use the database ID from your Notion database URL.
- Example format: `0123456789abcdef0123456789abcdef`

#### `notion.apiVersion`

- Use a Notion API version string.
- Default in this project: `2022-06-28`

#### `widget.title`

- Any plain text is allowed.
- Example: `My Tasks`, `Project Timeline`, `Sprint Board`

#### `widget.backgroundColor`

- Use one of the supported names:
  `black`, `white`, `red`, `green`, `blue`, `orange`, `yellow`, `pink`, `purple`, `cyan`, `mint`, `teal`, `indigo`, `brown`, `gray`, `darkGray`, `lightGray`
- Or use a hex color like `#1C1C1E` or `#FFFFFF`

#### `widget.textColor`

- Use the same options as `widget.backgroundColor`
- Examples: `white`, `black`, `#F5F5F5`

#### `widget.maxItemsMedium`

- Use any whole number greater than or equal to `1`
- Recommended range: `1` to `10`

#### `widget.maxItemsLarge`

- Use any whole number greater than or equal to `1`
- Recommended range: `1` to `20`

#### `widget.listStyle`

- Allowed values:
  `bullet`
  `numbered`

### Color values

Use either a color name or a hex code like `#RRGGBB`.

Supported names:

`black` · `white` · `red` · `green` · `blue` · `orange` · `yellow` · `pink` · `purple` · `cyan` · `mint` · `teal` · `indigo` · `brown` · `gray` · `darkGray` · `lightGray`

---

## Notes

- If the widget shows an error, double-check `widget-config.json` and confirm the Notion integration can access the target database.
- This setup avoids App Groups, which makes the project easier to build without paid Apple Developer capabilities.
- The project is intended to build locally without an Apple Developer team. The default signing identity is local ad hoc signing.
- If the widget does not appear in **Edit Widgets**, rebuild from Xcode, launch the app once from `/Applications`, and make sure the app bundle contains `Contents/PlugIns/NotionistWidgetExtension.appex`.
- If you use a custom Derived Data location, avoid building into a synced or metadata-heavy folder. A clean local build location works best for signing.

---

## Feedback and Contribution

This project is intended to be a small, modular tool for the Notion community. Feedback is welcome. To suggest changes, please submit a pull request.
