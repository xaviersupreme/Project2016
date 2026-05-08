# Project2016

A 2016 CoreGui remake for Roblox


<p align="left">

  <a href="https://github.com/xaviersupreme/Project2016/graphs/contributors">
    <img alt="Contributors" src="https://img.shields.io/github/contributors/xaviersupreme/Project2016" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/xaviersupreme/Project2016?color=0088ff" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016/pulls">
    <img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/xaviersupreme/Project2016?color=0088ff" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/xaviersupreme/Project2016?style=flat" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016/network/members">
    <img alt="Forks" src="https://img.shields.io/github/forks/xaviersupreme/Project2016?style=flat" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016">
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/xaviersupreme/Project2016" />
  </a>

  <a href="https://github.com/xaviersupreme/Project2016">
    <img alt="Repo Size" src="https://img.shields.io/github/repo-size/xaviersupreme/Project2016" />
  </a>
</p>

> [!NOTE]
> Originally by **lxte**, modded by **me**. Inspired by spec / scot.wtf's Project2016.
>
> there WILL be bugs.. 😈 (Make a PR if you find any bugs or want a feature)

## Features

- **2016 Topbar**
- **Old Developer Console** 
- **Old Graphics**
- **Old Bubble Chat**
- **Old Player List**
- **Old escape menu**
- **Custom Topbar Icons**
- **FPS Counter**
- **Old Stud Textures**
- **Old Cursor** 

## Pictures

<p align="center">
  <img src="./assets/PlrMenu.png" height="220"/>
  <img src="./assets/Topbar1.png" height="220"/>
  <img src="./assets/chat.png" height="220"/>
  <img src="./assets/dev.png" height="220"/>
  <img src="./assets/menusettinsg.png" height="220"/>
  <img src="./assets/playerlist.png" height="220"/>
  <img src="./assets/plrdropdown.png" height="220"/>
  <img src="./assets/topbarcustom.png" height="220"/>
</p>

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
