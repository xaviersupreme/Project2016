-- Services
local CoreGui = game:GetService("CoreGui");
local MarketPlaceService = game:GetService("MarketplaceService");
local Players = game:GetService("Players");

-- Functions
local Spawn = task.spawn
local Create = function(Class: string, Properties: { [string]: any })
    local Object = Instance.new(Class);

    for Property, Value in next, (Properties or {}) do
        Object[Property] = Value
    end

    return Object
end

-- Init
local ScreenGui = Create("ScreenGui", {
    Parent = CoreGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 2147483647,
    ResetOnSpawn = false,
})

local Background = Create("ImageLabel", {
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 0,
    Image = "rbxasset://textures/loading/darkLoadingTexture.png",
    ScaleType = Enum.ScaleType.Tile,
    TileSize = UDim2.new(0, 512, 0, 512)
})

local Logo = Create("ImageLabel", {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.855, 0, 0.745, 0),
    Size = UDim2.new(0, 128, 0, 128),
    ZIndex = 1,
    Image = "rbxasset://textures/loading/loadingCircle.png"
})

local GameLoadText = Create("TextLabel", {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.07, 0, 0.787, 0),
    Size = UDim2.new(0, 60, 0, 26),
    ZIndex = 1,
    Text = "Requesting game name...",
    TextSize = 36,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left
})

local OwnerLoadText = Create("TextLabel", {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.07, 0, 0.826, 0),
    Size = UDim2.new(0, 90, 0, 39),
    ZIndex = 1,
    Text = "Requesting username...",
    TextSize = 28,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left
})

local LoadingText = Create("TextLabel", {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.876301765, 0, 0.805, 0),
    Size = UDim2.new(0, 60, 0, 26),
    ZIndex = 1,
    Text = "Loading...",
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Center
})

Spawn(function()
    repeat task.wait();
        Logo.Rotation += 7
    until (not Logo.Parent)
end)

Spawn(function()
    GameLoadText.Text = MarketPlaceService:GetProductInfo(game.PlaceId).Name
    OwnerLoadText.Text = `By { Players:GetNameFromUserIdAsync(game.CreatorId) }`
end)

Spawn(function()
    repeat task.wait(1)
        LoadingText.Text = "Loading."
        task.wait(1)
        LoadingText.Text = "Loading.."
        task.wait(1)
        LoadingText.Text = "Loading..."
    until (not LoadingText.Parent)
end)

if (not game:IsLoaded()) then
    game.Loaded:Wait();
end

task.wait(0.5); ScreenGui:Destroy()
