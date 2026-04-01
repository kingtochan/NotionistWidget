# Notionist Widget

Open-source macOS desktop widget that lists upcoming rows from a Notion database. Supported columns are **Name** (title), optional **Date** (date), and optional **Status** (select). The widget refreshes from Notion every 30 minutes.

---

## Install

This project is distributed as source only. There is no prebuilt `.app`.

The widget is configured before build time through a bundled JSON file, so it does not depend on App Groups or runtime settings sharing between the app and widget.

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

**Option A — Xcode**

1. Open `NotionistWidget.xcodeproj` in Xcode.
2. Select the **NotionistWidgetApp** scheme and **My Mac** as the destination.
3. Build and run.
4. Right-click your desktop → **Edit Widgets** → search **Notionist** → add the widget.

If you change `widget-config.json`, rebuild the app so the updated config is bundled into the widget.

**Option B — Command line**

```zsh
xcodebuild \
  -project NotionistWidget.xcodeproj \
  -scheme NotionistWidgetApp \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The built app is written to Xcode's DerivedData folder.

---

## How It Works

- `NotionistWidgetApp` is a lightweight container app for the widget.
- `WidgetExtension` reads settings from the bundled `Config/widget-config.json` file.
- To change credentials or display options, edit the JSON file and rebuild.

---

## Configuration Reference

| Key | Description |
|---|---|
| `notion.token` | Your Notion integration secret (`secret_...`) |
| `notion.databaseId` | 32-character ID from the Notion database URL |
| `notion.apiVersion` | Notion API version header to send |
| `widget.title` | Header text shown on the widget |
| `widget.backgroundColor` | Color name or hex code |
| `widget.textColor` | Color name or hex code |
| `widget.maxItemsMedium` | Number of rows to show on a medium widget |
| `widget.maxItemsLarge` | Number of rows to show on a large widget |
| `widget.listStyle` | `bullet` or `numbered` |

### Color values

Use either a color name or a hex code like `#RRGGBB`.

Supported names:

`black` · `white` · `red` · `green` · `blue` · `orange` · `yellow` · `pink` · `purple` · `cyan` · `mint` · `teal` · `indigo` · `brown` · `gray` · `darkGray` · `lightGray`

---

## Notes

- If the widget shows an error, double-check `widget-config.json` and confirm the Notion integration can access the target database.
- This setup avoids App Groups, which makes the project easier to build without paid Apple Developer capabilities.

---

## Feedback and Contribution

This project is intended to be a small, modular tool for the Notion community. Feedback is welcome. To suggest changes, please submit a pull request.
