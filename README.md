# Notionist Widget

Open-source macOS desktop widget that directly lists upcoming rows from a Notion database (columns: **Name** title, optional **Date** date, optional **Status** select). This project was inspired by the fact that currently there is no official widget that provides a quick view on a particular page or database from Notion. It is useful for keeping track of to-do list or project timeline to increase productivity. The list is updated from Notion database every half an hour.

---

## Install

This project is currently distributed as source only.

Prebuilt `.app` is not included due to lack of signature. If you want to use the widget, please build it locally in Xcode.

---

## Build from Source

If you prefer to build the app yourself (no trust required):

### Prerequisites

- macOS 13 or later
- Xcode 15 or later

### Step 1 — Notion setup

1. Create an [integration](https://www.notion.so/my-integrations), copy its secret token.
2. Open your Notion database, click **…** → **Connections** and share it with your integration.
3. Find the database ID in the URL — it's the string between the last `/` and the `?`.

### Step 2 — Signing note

The app and widget exchange settings through an App Group entitlement.

If Xcode lets you sign both targets with a profile that supports App Groups, the setup should work normally.

If you are using a free Apple ID or no Apple Developer membership, Xcode may refuse the App Groups capability. In that case:

1. The project may still build locally.
2. The settings app may still open.
3. The widget may not be able to read the saved configuration from the host app.

That limitation is caused by Apple's signing/capability restrictions, not by a downloadable release from this repository.

### Step 3 — Build & run

**Option A — Xcode (recommended)**

1. Select the **NotionistWidgetApp** scheme and **My Mac** as the destination.
2. Press **⌘R**.
3. The settings window opens. Fill in your token, database ID, and any display preferences, then click **Save & Reload Widget**.
4. Right-click your desktop → **Edit Widgets** → search **Notionist** → add the widget.

If the widget still shows no items after saving, the most likely cause is that App Groups was not enabled successfully for your signing setup.

To keep the widget after Xcode is closed, drag the `.app` from **Product → Show Build Folder in Finder** to `/Applications` and launch it once from there.

**Option B — Command line**

```zsh
xcodebuild \
  -project NotionistWidget.xcodeproj \
  -scheme NotionistWidgetApp \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

The `.app` is written to Xcode's DerivedData folder. Move it to `/Applications` and launch it once.

---

## Settings

All settings are changed through the app's settings window at runtime — no rebuild needed.

| Setting | Description |
|---|---|
| **Integration Token** | Your Notion integration secret (`secret_...`) |
| **Database ID** | 32-character ID from the Notion database URL |
| **Widget Title** | Header text shown on the widget |
| **Background Color** | Color name or hex code (see below) |
| **Text Color** | Color name or hex code (see below) |
| **Max Items — Medium** | How many rows to show on a medium widget |
| **Max Items — Large** | How many rows to show on a large widget |
| **List Style** | `bullet` or `numbered` |

### Color values

Accepts a **color name** (case-insensitive) or a **hex code** (`#RRGGBB`):

`black` · `white` · `red` · `green` · `blue` · `orange` · `yellow` · `pink` · `purple` · `cyan` · `mint` · `teal` · `indigo` · `brown` · `gray` · `darkGray` · `lightGray`

---

## Feedback and Contribution

This is intended to be a small modular tool to help the Notion community. Any feedback is welcomed. To suggest changes, simply submit a push request for your commit.
