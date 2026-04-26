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

    ReplaceAgeGroupMessage = true,
    HideVoiceChatButton = false,
    HideGameIcons = false,

    FPSCounter = false,
    OldStudTextures = false,
    OldCursor = true,
})

local Repo = "https://raw.githubusercontent.com/xaviersupreme/Project2016/main/"
loadstring(game:HttpGet(Repo .. "modules/core.lua"))();
