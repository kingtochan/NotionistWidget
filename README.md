# Notionist Widget

Open-source macOS desktop widget that directly lists upcoming rows from a Notion database (columns: **Name** title, optional **Date** date, optional **Status** select). This project was inspired by the fact that currently there is no official widget that provides a quick view on a particular page or database from Notion. It is useful for keeping track of to-do list or project timeline to increase productivity. The list is updated from Notion database every half an hour.

---

## Install — Prebuilt (no Xcode required)

1. Go to the [**Releases**](../../releases/latest) page and download the latest `NotionistWidget-v1.0.0.zip`.
2. Unzip and move **NotionistWidgetApp.app** to your `/Applications` folder.
3. **Right-click → Open** the app (required once — macOS blocks unsigned apps on a plain double-click).
4. The settings window opens. Enter your Notion credentials and preferences, then click **Save & Reload Widget**.
5. Right-click your desktop → **Edit Widgets** → search **Notionist** → add the widget.

> **Why right-click → Open?** The prebuilt binary is ad-hoc signed but not notarized with Apple. This is a one-time step; after the first launch macOS remembers your choice.

---

## Publishing a Release (for maintainers)

1. Run the build script from the project root:
   ```zsh
   ./build-release.sh 1.0.0
   ```
   This produces `NotionistWidget-v1.0.0.zip` in the project root.
2. Commit and push your changes via **GitHub Desktop**.
3. On [github.com](https://github.com) → your repo → **Releases** → **Draft a new release**.
4. Create a new tag (e.g. `v1.0.0`), write release notes, and upload the `.zip` file.
5. Click **Publish release**.

---

## Install — Build from Source

If you prefer to build the app yourself (no trust required):

### Prerequisites

- macOS 13 or later
- Xcode 15 or later

### Step 1 — Notion setup

1. Create an [integration](https://www.notion.so/my-integrations), copy its secret token.
2. Open your Notion database, click **…** → **Connections** and share it with your integration.
3. Find the database ID in the URL — it's the 32-character string between the last `/` and the `?`.

### Step 2 — App Group (one-time Xcode setup)

The app and widget share settings via an App Group. You must enable this capability before building:

1. Open `NotionistWidget.xcodeproj` in Xcode.
2. Select the **NotionistWidgetApp** target → **Signing & Capabilities** → **+ Capability** → **App Groups**.
3. Add the group ID: `group.com.example.notionistwidget`
4. Repeat for the **NotionistWidgetExtension** target using the **same** group ID.

### Step 3 — Build & run

**Option A — Xcode (recommended)**

1. Select the **NotionistWidgetApp** scheme and **My Mac** as the destination.
2. Press **⌘R**.
3. The settings window opens — fill in your token, database ID, and any display preferences, then click **Save & Reload Widget**.
4. Right-click your desktop → **Edit Widgets** → search **Notionist** → add the widget.

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

This is intended to be a small modular tool to help the Notion community. Any feedback is welcomed. To suggest changes, simply submit a pull request for your commit.
