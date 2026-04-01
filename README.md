# Notionist Widget

macOS desktop widget that directly lists upcoming rows from a Notion database (columns: **Name** title, optional **Date** date, optional **Status** select). This project was inspired by the fact that currently there is no official widget that provides a quick view on a particular page or database from Notion.

## Setup

1. In Notion, create an [integration](https://www.notion.so/my-integrations), copy its token, and **share** your database with that integration.
2. Find the database ID in the URL of the database full page. The ID is the chain between the last slash (/) and the question mark (?) in the URL.
3. Edit **`Shared/WidgetConfig.json`**:
   - **`notion`**: `token`, `databaseId`, optional `apiVersion` (default `2022-06-28`).
   - **`widget`**: `title`, `backgroundColorHex` (`#RRGGBB` or `#RRGGBBAA`), `maxItemsMedium`, `maxItemsLarge`, `listStyle` (`bullet` or `numbered`).

Values are **bundled at build time** — change the JSON, then rebuild.

```zsh
git clone https://github.com/YOUR_USER/NotionistWidget.git
cd NotionistWidget
# edit Shared/WidgetConfig.json, then build below
```

## Build

No pre-built binary is provided. This project is designed to be built from source locally.

**Requirements:** macOS 13+, Xcode 15+

### Option A — Xcode (recommended)

1. Open `NotionistWidget.xcodeproj` in Xcode.
2. Select the **NotionistWidgetApp** scheme and your Mac as the destination.
3. Press **⌘R** (Product → Run).
4. Once running, add **Notionist Widget** from the desktop via **Edit Widgets**.

To keep the widget after Xcode is closed, drag the built `.app` from the **Products** group in the Project Navigator to `/Applications`, then launch it once from there.

### Option B — Command line

```zsh
xcodebuild \
  -project NotionistWidget.xcodeproj \
  -scheme NotionistWidgetApp \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

The `.app` is written to Xcode's DerivedData folder (not included in this repo). Run `xcodebuild -showBuildSettings | grep BUILT_PRODUCTS_DIR` to find the exact path.
