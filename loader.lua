-- [>] Project2016 Loader
-- [!] https://github.com/xaviersupreme/Project2016

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

local Repo = "https://raw.githubusercontent.com/xaviersupreme/Project2016/main/"

if (not game:IsLoaded()) then
	pcall(function()
		loadstring(game:HttpGet(Repo .. "modules/loading.lua"))();
	end)

	if (not game:IsLoaded()) then
		game.Loaded:Wait();
	end
end

loadstring(game:HttpGet(Repo .. "modules/core.lua"))();
