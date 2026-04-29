# Project2016

A 2016 CoreGui remake for Roblox

> Originally by **lxte**, modded by **xavier**. Inspired by spec / scot.wtf's Project2016.

## Features

- **2016 Topbar** -- Classic TopBar Icons
- **Old Developer Console** -- Modded classic developer console
- **Old Graphics** -- Classic Enum.Technology.Compatibility lighting
- **Old Bubble Chat** -- Classic bubble chat style (if u even have chat lolx)
- **Old Player List** -- Old UI Player list
- **Custom Topbar Icons** -- Game made topbar icons are automatically styled
- **FPS Counter** -- Optional FPS display in the topbar
- **Old Stud Textures** -- Old stud overlays on plastic parts
- **Old Cursor** - Old arrow cursor

## Configuration

Edit the `Config2016` table in the script:

```lua
-- [>] Project2016 Loader
-- [!] https://github.com/xaviersupreme/Project2016

if (not game:IsLoaded()) then
	game.Loaded:Wait();
end

getgenv().Config2016 = getgenv().Config2016 or ({
    OldConsole = true,
    OldGraphics = true,
    OldPlayerList = true,
    OldBubbleChat = true,
    OldEscapeMenu = true,

    ReplaceAgeGroupMessage = true,
    HideVoiceChatButton = false,
    HideGameIcons = false,

    FPSCounter = false,
    OldStudTextures = false,
    OldCursor = true,
})

loadstring(game:HttpGet("https://raw.githubusercontent.com/xaviersupreme/Project2016/main/modules/core.lua"))();

```

## Structure

```
Project2016/
|-- loader.lua          # Loader Script
|-- modules/
|   |-- core.lua        # Main CoreGui Modder
|   |-- console.lua     # Old developer console
|   |-- settings.lua    # Old escape menu
|-- README.md << you are here :P
```
