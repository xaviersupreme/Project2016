-- [>] Core2016 by lxte / Modded by xavier
-- [!] inspired by spec / scot.wtf's Project2016

local Repo = "https://raw.githubusercontent.com/xaviersupreme/Project2016/main/"

-- Services
local CoreGui = game:GetService("CoreGui");
local TextChatService = game:GetService("TextChatService");
local Lighting = game:GetService("Lighting");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local Players = game:GetService("Players");
local Teams = game:GetService("Teams");
local PolicyService = game:GetService("PolicyService");

-- Variables
local RobloxGui = CoreGui:WaitForChild("RobloxGui");
local ExperienceChat = CoreGui:WaitForChild("ExperienceChat");
local ExperienceChatApp = ExperienceChat:WaitForChild("appLayout");
local TopBarApp = CoreGui:WaitForChild("TopBarApp"):WaitForChild("TopBarApp");
local UnibarMenu = TopBarApp:WaitForChild("UnibarLeftFrame"):WaitForChild("UnibarMenu");
local MenuIconHolder = TopBarApp:WaitForChild("MenuIconHolder")
local RobloxMenu = MenuIconHolder:WaitForChild("TriggerPoint"):WaitForChild("IconHitArea");
local ChatHolder = UnibarMenu:WaitForChild("2"):WaitForChild("3");

-- Player
local LocalPlayer = Players.LocalPlayer

-- Global
local Core2016 = getgenv().Core2016
local Configuration = ({
	OldConsole = true,
	OldGraphics = true,
	OldPlayerList = true,
	OldBubbleChat = true,
	OldEscapeMenu = true,

	ReplaceAgeGroupMessage = true,
	HideVoiceChatButton = false,
	HideGameIcons = false,

	FPSCounter = true,
	OldStudTextures = false,
	OldCursor = true,
})

for Key, Value in next, (getgenv().Config2016 or {}) do
	Configuration[Key] = Value
end

getgenv().Config2016 = Configuration

if (getgenv().Core2016Data) then
	for _, Connection in next, (getgenv().Core2016Data.Connections or {}) do
		pcall(function()
			Connection:Disconnect();
		end)
	end

	for _, Object in next, (getgenv().Core2016Data.Objects or {}) do
		pcall(function()
			Object:Destroy();
		end)
	end
end

for _, Object in next, CoreGui:GetChildren() do
	if ((Object.Name == "Project2016RobloxGui") or (Object.Name == "Settings2016Gui") or (Object.Name == "Core2016SettingsGui")) then
		pcall(function()
			Object:Destroy();
		end)
	elseif (Object.Name == "RobloxGui" and Object:IsA("ScreenGui") and not Object:FindFirstChild("Modules")) then
		pcall(function()
			Object:Destroy();
		end)
	end
end

getgenv().Core2016 = nil
Core2016 = nil

-- Luau
local Spawn, Wait, Defer = task.spawn, task.wait, task.defer
local Byte, Sub, Format, Match, Find, Replace = string.byte, string.sub, string.format, string.match, string.find, string.gsub
local Floor, Random, Clamp = math.floor, math.random, math.clamp
local Discover, Insert = table.find, table.insert

local Core2016Data = ({
	Connections = ({}),
	Objects = ({}),
})
getgenv().Core2016Data = Core2016Data

local RawConnect = (game.Loaded.Connect);
local Connect = function(Signal, Callback)
	local Connection = RawConnect(Signal, Callback);
	Insert(Core2016Data.Connections, Connection);
	return Connection
end
local Clone = (game.Clone);
local Destroy = (game.Destroy);
local Changed = (game.GetPropertyChangedSignal);

-- Functions
local Create = function(Class: string, Properties: { [string]: any })
	local Object = Instance.new(Class);

	for Property, Value in next, (Properties or {}) do
		Object[Property] = Value
	end

	return Object
end

local ColorOffset = 0
local GetPlayerColor = function(PlayerName)
	local Value = 0

	for Index = 1, #PlayerName do
		local NewValue = Byte(Sub(PlayerName, Index, Index));
		local Reverse = (#PlayerName - Index + 1);

		if (#PlayerName % 2 == 1) then
			Reverse -= 1
		end

		if (Reverse % 4 >= 2) then
			NewValue = -NewValue
		end

		Value += NewValue
	end

	local ChatColors = ({
		Color3.new(253/255, 41/255, 67/255),
		Color3.new(1/255, 162/255, 255/255),
		Color3.new(2/255, 184/255, 87/255),
		BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	});

	local Color = ChatColors[((Value + ColorOffset) % #ChatColors) + 1]
	return Format("#%02x%02x%02x", Floor(Color.R * 255), Floor(Color.G * 255), Floor(Color.B * 255));
end

local IsUnder13Cache = ({})
local IsUnder13 = function(Player)
	if (IsUnder13Cache[Player.UserId] ~= nil) then
		return IsUnder13Cache[Player.UserId]
	end

	local Success, Policy = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(Player)
	end)

	if (not Success or not Policy) then
		IsUnder13Cache[Player.UserId] = true
		return true
	end

	local Over = false
	if (Policy.AreAdsAllowed == true) then Over = true end
	if (Policy.AllowedExternalLinkReferences and #Policy.AllowedExternalLinkReferences > 0) then Over = true end
	if (Policy.IsPaidItemTradingAllowed == true) then Over = true end

	IsUnder13Cache[Player.UserId] = not Over
	return not Over
end

-- might just remove this function
local UpdatePosition = function(Button, Position)
	Button.Position = Position
	Connect(Changed(Button, "Position"), function()
		if (Button.Position ~= Position) then
			Button.Position = Position
		end
	end)
end

local GetImage = function(Type: "Backpack" | "Chat" | "Menu", Visible)
	local Images = {
		Backpack = {
			["true"] = "rbxasset://textures/ui/Backpack/Backpack_Down.png",
			["false"] = "rbxasset://textures/ui/Backpack/Backpack.png",
		},

		Chat = {
			["true"] = "rbxasset://textures/ui/Chat/ChatDown.png",
			["false"] = "rbxasset://textures/ui/Chat/Chat.png",
		},

		Menu = {
			["true"] = "rbxasset://textures/ui/Menu/HamburgerDown.png",
			["false"] = "rbxasset://textures/ui/Menu/Hamburger.png",
		},
	}

	return Images[Type][tostring(Visible)]
end

local LoadProjectModule = function(ModuleName)
	return loadstring(game:HttpGet(Repo .. "modules/" .. ModuleName .. ".lua"))();
end

local CreateBackpack = function()
	if (not Core2016) then
		local DotButton = ChatHolder:WaitForChild("nine_dot");
		local Button = Clone(DotButton);

		Button.Parent = ChatHolder
		Button.Name = "_Backpack"
		Button.Visible = true

		return Button
	end

	return nil -- so my vscode stops yelling
end

local FormatNumber = function(Value)
	if (typeof(Value) == "number") then
		Value = Floor(Value);

		if (Value >= 1000000000000) then
			return string.format("%.1fT+", Value / 1000000000000);
		elseif (Value >= 1000000000) then
			return string.format("%.1fB+", Value / 1000000000);
		elseif (Value >= 1000000) then
			return string.format("%.1fM+", Value / 1000000);
		elseif (Value >= 1000) then
			local Formatted = tostring(Value);
			return Formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "");
		else
			return tostring(Value);
		end
	else
		return Value
	end
end

local AddIconSystem = function(Button, Size, Clicked: () -> ())
	if (not Button) then
		return function() end
	end

	local IntegrationIconFrame = Button:FindFirstChild("IntegrationIconFrame", 0.5);
	local RobloxMenu = Button:FindFirstChild("ScalingIcon");
	local Highlighter = Button:FindFirstChild("Highlighter") or Button:FindFirstChild("StateOverlayRound");
	local IntegrationIcon = RobloxMenu or IntegrationIconFrame:FindFirstChild("IntegrationIcon");
	local Icon = nil

	if (IntegrationIcon) then
		local Previous = IntegrationIcon.Parent:FindFirstChild("ICON_IMAGE");

		if (Previous) then
			Icon = Previous
		else
			Icon = Create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = Size or IntegrationIcon.Size,
				Parent = IntegrationIcon.Parent,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Name = "ICON_IMAGE",
			})

			IntegrationIcon.Visible = false
		end
	end

	if (Clicked) then
		Spawn(function()
			Connect(Button:WaitForChild("IconHitArea_nine_dot").MouseButton1Click, Clicked);
		end)
	end

	if (Highlighter) then
		Highlighter.BackgroundTransparency = 1
		Highlighter.Visible = false
	end

	return function(ImageId: string)
		if (Icon) then
			Icon.Image = ImageId
		else
			warn("Can't set icon", debug.traceback());
		end
	end
end

local UpdateChatCounter = function()
	local Chat = ChatHolder:FindFirstChild("chat");
	local Badges = Chat and Chat:FindFirstChild("5");

	if (Badges) then
		for _, Badge in next, Badges:GetChildren() do
			if (Badge.Name == "Badge") then
				Badge.BackgroundColor3 = Color3.fromRGB(254, 54, 54);
				Badge.Position = UDim2.fromOffset(24, 4);
				Badge.Text.TextColor3 = Color3.fromRGB(255, 255, 255);
				Badge.Text.TextSize = 12
			end
		end
	end
end

-- this is a function because sometimes chat gets disabled and enabled using setcoreguienabled which breaks
local SetupChat = function()
	-- Buttons
	local Chat = ChatHolder:WaitForChild("chat", 2);
	local Backpack = ChatHolder:FindFirstChild("_Backpack")

	-- Objects
	local ChatDetection = ExperienceChatApp:WaitForChild("topBorder");
	local ChatBackground = ExperienceChatApp:WaitForChild("chatInputBar"):WaitForChild("Background");
	local ChatContainer = ChatBackground:WaitForChild("Container");
	local TextContainer = ChatContainer:WaitForChild("TextContainer");
	local TextBoxContainer = TextContainer:WaitForChild("TextBoxContainer", 1);
	local Badges = Chat and Chat:FindFirstChild("5");
	local ContainerPadding = TextContainer:WaitForChild("UIPadding");

	-- Configuration
	local ChatWindow = TextChatService:WaitForChild("ChatWindowConfiguration");
	local ChatInput = TextChatService:WaitForChild("ChatInputBarConfiguration");
	local ChatWindowMain = ExperienceChatApp:WaitForChild("chatWindow", 3);

	-- Icon Systems
	local ChatIconSystem = AddIconSystem(Chat, UDim2.fromOffset(28, 28));

	-- Backpack
	if (Backpack) then
		Backpack.Position = UDim2.fromOffset(48, 0);
	end

	-- Chat Redesign
	ChatWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	ChatWindow.BackgroundTransparency = 0.6
	ChatWindow.TextSize = 16
	ChatWindow.TextStrokeTransparency = 0.6
	ChatWindow.HeightScale = 0.85
	ChatWindow.WidthScale = 1.1
	ChatWindow.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	ChatInput.BackgroundColor3 = Color3.fromRGB(209, 216, 221);
	ChatInput.BackgroundTransparency = 0.5
	ChatInput.TextColor3 = Color3.fromRGB(25, 25, 25);
	ChatInput.PlaceholderColor3 = Color3.fromRGB(36, 35, 34);
	ChatInput.TextStrokeTransparency = 1
	ChatInput.TextSize = 16
	ChatInput.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	ExperienceChatApp.Position = UDim2.fromOffset(0, -20);
	ExperienceChatApp.topBorder.Image = "rbxassetid://70944149509141"
	ExperienceChatApp.bottomBorder.Image = "rbxassetid://70944149509141"
	ChatBackground:WaitForChild("Corner").CornerRadius = UDim.new(0, 0);
	ChatContainer:WaitForChild("SendButton").Visible = false
	ExperienceChatApp:WaitForChild("bottomBorder").Size = UDim2.new(1, 0, 0, 4);
	ChatBackground.Position = UDim2.fromOffset(-3, -3);
	ChatBackground.Size = UDim2.new(1, 6, 0, 0);
	ContainerPadding.PaddingTop = UDim.new(0, 5);
	ContainerPadding.PaddingBottom = UDim.new(0, 5);
	ChatBackground.Parent.LayoutOrder = 4

	if (TextBoxContainer) then
		TextBoxContainer.Position = UDim2.fromScale(1, 0);
		TextBoxContainer.Size = UDim2.new(1, -8, 0, 0);
		TextBoxContainer:WaitForChild("TextBox").Position = UDim2.fromOffset(-10, 0)
	end

	if (not ExperienceChatApp:FindFirstChild("Seperator")) then
		Create("Frame", {
			Name = "Seperator",
			Parent = ExperienceChatApp,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(10, 1),
			LayoutOrder = 3,
		})
	end

	if (ChatWindowMain) then
		Spawn(function()
			local DotMenu = ChatWindowMain:WaitForChild("TopBanner", 10000):WaitForChild("DotMenu", 10000)
			DotMenu.Visible = false
			Connect(Changed(DotMenu, "Visible"), function()
				DotMenu.Visible = false
			end)
		end)

		-- update the chat player format (Player1: Message -> [Player1]: Message)
		local ScrollingView = ChatWindowMain:WaitForChild("scrollingView", 2);
		local BottomLockedScrollView = ScrollingView and ScrollingView:WaitForChild("bottomLockedScrollView", 2);
		local ScrollView = BottomLockedScrollView and BottomLockedScrollView:WaitForChild("RCTScrollView", 2);
		local Chats = ScrollView and ScrollView:WaitForChild("RCTScrollContentView", 2);
		local Padding = BottomLockedScrollView and BottomLockedScrollView:WaitForChild("padding", 1);

		local UpdateChatMessage = function(Message)
			local TextMessage = Message and Message:FindFirstChild("TextMessage");

			if (TextMessage) then
				local BodyText = TextMessage:FindFirstChild("BodyText");
				local PrefixText = TextMessage:FindFirstChild("PrefixText");
				local UserId = tonumber(Match(Message.Name, "^(%d+)-"));
				local Player = UserId and Players:GetPlayerByUserId(UserId);

				if (UserId and Player) then
					local AgeGroupDifference = Find(BodyText.Text, "🔒 :");
					local TeamMessage = Find(PrefixText.Text, "%[Team%]");
					local TeamPrefix = (TeamMessage and "[Team] " or "");
					local ToReplace = ((AgeGroupDifference and "🔒 :") or `{Player.DisplayName}:`);

					local Body = (`<font color="{GetPlayerColor(Player.Name)}"><b>{TeamPrefix}[{Player.Name}]:</b></font> {Match(BodyText.Text, "</stroke></font>%s*(.*)$") or Match(BodyText.Text, ToReplace .. "%s*(.*)$") or ""}`);
					local Prefix = (`<font color="{GetPlayerColor(Player.Name)}"><b>{TeamPrefix}[{Player.Name}]:</b></font>`);

					PrefixText.Text = Prefix
					BodyText.Text = Body
					BodyText.TextColor3 = Color3.fromRGB(255, 255, 255);

					Connect(Changed(PrefixText, "Text"), function()
						PrefixText.Text = Prefix
					end)

					Connect(Changed(BodyText, "Text"), function()
						BodyText.Text = Body
					end)

					if (AgeGroupDifference) then
						BodyText.TextColor3 = Color3.fromRGB(250, 255, 158);
					end
				elseif (UserId == 0 and BodyText and Find(BodyText.Text:lower(), "age group") and Configuration.ReplaceAgeGroupMessage) then
					BodyText.Text = "Chat '/?' or '/help' for a list of chat commands."

					Connect(Changed(BodyText, "Text"), function()
						BodyText.Text = "Chat '/?' or '/help' for a list of chat commands."
					end)
				end
			end
		end

		if (Chats) then
			Connect(Chats.ChildAdded, UpdateChatMessage);
			for _, ChatObject in next, Chats:GetChildren() do
				UpdateChatMessage(ChatObject);
			end
		end

		if (Padding) then
			Padding.PaddingBottom = UDim.new(0, 4);
			Padding.PaddingTop = UDim.new(0, -4);
		end

		if (ScrollView) then
			ScrollView.ScrollBarThickness = 1
		end
	end

	if (Chat) then
		UpdatePosition(Chat, UDim2.fromOffset(4, 0));
	end

	-- Connections
	if (Badges) then
		UpdateChatCounter();
		Connect(Badges.ChildAdded, UpdateChatCounter);
		Connect(Badges.ChildRemoved, UpdateChatCounter);
	end

	ChatIconSystem(GetImage("Chat", ChatDetection.Visible));
	Connect(Changed(ChatDetection, "Visible"), function()
		ChatIconSystem(GetImage("Chat", ChatDetection.Visible));
	end)
end

-- Game Icon System
local StyledTopbarIcons = ({})
local GameIconHolder = nil
local TopbarGuiNames = ({ "TopbarPlus", "TopbarStandard", "TopbarStandardClipped", "TopbarCenteredClipped", "TopbarCentered" })

local MirrorGameIcon = function(Source, ImageId, LabelText, ClickTarget, VisibilitySource)
	if (StyledTopbarIcons[Source]) then
		return
	end

	if (not GameIconHolder) then
		return
	end

	local HasImage = ImageId and ImageId ~= ""
	local HasText = LabelText and LabelText ~= ""
	if (not HasImage and not HasText) then return end

	local ButtonWidth = (HasText and HasImage) and 72 or (HasText and not HasImage) and 72 or 44

	local Mirror = Create("ImageButton", {
		Parent = GameIconHolder,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, ButtonWidth, 0, 44),
		Name = "GameIcon_Mirror",
		AutoButtonColor = false,
	})

	if (HasImage) then
		local ImgSource = nil
		if (typeof(ImageId) == "string") then
			ImgSource = ImageId
		end

		local Img = Create("ImageLabel", {
			Parent = Mirror,
			BackgroundTransparency = 1,
			Position = HasText and UDim2.fromOffset(4, 0) or UDim2.fromScale(0.5, 0.5),
			AnchorPoint = HasText and Vector2.new(0, 0) or Vector2.new(0.5, 0.5),
			Size = HasText and UDim2.new(0, 24, 1, 0) or UDim2.fromOffset(24, 24),
			ScaleType = Enum.ScaleType.Fit,
			Image = ImgSource or "",
		})
	end

	if (HasText) then
		Create("TextLabel", {
			Parent = Mirror,
			BackgroundTransparency = 1,
			Position = HasImage and UDim2.fromOffset(30, 0) or UDim2.new(0, 0, 0, 0),
			Size = HasImage and UDim2.new(1, -34, 1, 0) or UDim2.fromScale(1, 1),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			Text = LabelText,
			TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		})
	end

	if (ClickTarget) then
		Connect(Mirror.MouseButton1Click, function()
			if (ClickTarget:IsA("TextButton") or ClickTarget:IsA("ImageButton")) then
				firesignal(ClickTarget.MouseButton1Click)
			elseif (ClickTarget:IsA("Frame")) then
				local Btn = ClickTarget:FindFirstChildWhichIsA("TextButton") or ClickTarget:FindFirstChildWhichIsA("ImageButton")
				if (Btn) then firesignal(Btn.MouseButton1Click); end
			end
		end)
	end

	local VS = VisibilitySource or Source
	Connect(Changed(VS, "Visible"), function()
		Mirror.Visible = VS.Visible
	end)

	Mirror.Visible = true
	StyledTopbarIcons[Source] = Mirror
end

-- TopbarPlus v2 handler
local ProcessTopbarPlus = function(ScreenGui)
	local Container = ScreenGui:FindFirstChild("TopbarContainer");
	if (not Container) then return end

	if (Configuration.HideGameIcons) then
		ScreenGui.Enabled = false
		return
	end

	Container.Visible = false

	local ProcessIcon = function(IconFrame)
		if (not IconFrame:IsA("Frame") or not IconFrame:FindFirstChild("IconButton")) then return end
		if (Find(IconFrame.Name, "_overflow") or Find(IconFrame.Name, "_Topbar")) then return end

		local IconButton = IconFrame:FindFirstChild("IconButton");
		local IconImage = IconButton and IconButton:FindFirstChild("IconImage");
		local IconLabel = IconButton and IconButton:FindFirstChild("IconLabel");

		MirrorGameIcon(
			IconFrame,
			IconImage and IconImage.Image,
			IconLabel and IconLabel.Text,
			IconButton,
			IconFrame
		)
	end

	for _, Child in next, Container:GetChildren() do
		ProcessIcon(Child);
	end

	Connect(Container.ChildAdded, function(Child)
		Wait(0.1);
		ProcessIcon(Child);
	end)
end

-- TopbarStandard / v3 handler
local ProcessTopbarStandard = function(ScreenGui)
	local Holders = ScreenGui:FindFirstChild("Holders");
	if (not Holders) then return end

	if (Configuration.HideGameIcons) then
		ScreenGui.Enabled = false
		return
	end

	local ProcessWidget = function(Widget)
		if (not Widget:IsA("Frame")) then return end
		if (Find(Widget.Name, "Overflow")) then return end

		local IconButton = Widget:FindFirstChild("IconButton");
		if (not IconButton) then return end

		local Menu = IconButton:FindFirstChild("Menu");
		local IconSpot = Menu and Menu:FindFirstChild("IconSpot");
		if (not IconSpot) then return end

		local Contents = IconSpot:FindFirstChild("Contents");
		local ClickRegion = IconSpot:FindFirstChild("ClickRegion");

		local ImageId, LabelText = "", ""
		if (Contents) then
			local Img = Contents:FindFirstChild("IconImage", true);
			local Lbl = Contents:FindFirstChild("IconLabel", true);
			ImageId = Img and Img.Image or ""
			LabelText = Lbl and Lbl.Text or ""
		end

		Widget.Visible = false
		MirrorGameIcon(Widget, ImageId, LabelText, ClickRegion, Widget)
	end

	for _, Side in next, Holders:GetChildren() do
		if (not Side:IsA("ScrollingFrame")) then continue end
		for _, Widget in next, Side:GetChildren() do
			ProcessWidget(Widget);
		end

		Connect(Side.ChildAdded, function(Widget)
			Wait(0.1);
			ProcessWidget(Widget);
		end)
	end
end

local WatchGameIcons = function()
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");

	local WatchGui = function(Child)
		if (not Child:IsA("ScreenGui")) then return end
		if (not Discover(TopbarGuiNames, Child.Name)) then return end

		if (Child.Name == "TopbarPlus") then
			ProcessTopbarPlus(Child);
			Connect(Child.ChildAdded, function(Inner)
				if (Inner.Name == "TopbarContainer" and Inner:IsA("Frame")) then
					ProcessTopbarPlus(Child);
				end
			end)
		else
			ProcessTopbarStandard(Child);
		end
	end

	for _, Child in next, PlayerGui:GetChildren() do
		WatchGui(Child);
	end

	Connect(PlayerGui.ChildAdded, function(Child)
		Wait(0.5);
		WatchGui(Child);
	end);
end

-- this the main function that redesigns the coregui
local Redesign = function()
	-- Buttons
	local Remove = ChatHolder:WaitForChild("nine_dot");
	local BackpackButton = ChatHolder:FindFirstChild("_Backpack") or CreateBackpack();
	local Chat = ChatHolder:WaitForChild("chat", 2);

	-- Other
	local Inventory = RobloxGui:WaitForChild("Backpack"):WaitForChild("Inventory");
	local Menu = RobloxGui:WaitForChild("SettingsClippingShield"):WaitForChild("SettingsShield");

	-- Icon Systems
	local RobloxIconSystem = AddIconSystem(RobloxMenu, UDim2.fromOffset(30, 24));
	local BackpackIconSystem = AddIconSystem(BackpackButton, UDim2.fromOffset(24, 30), function()
		Wait(0.001); keypress(0xC0); keyrelease(0xC0);
	end);

	-- Background
	ChatHolder.Parent:WaitForChild("2").BackgroundTransparency = 1
	RobloxMenu.BackgroundTransparency = 1

	-- Hide dots
	Remove.Visible = false

	-- Positions
	UnibarMenu.Parent.Position = UDim2.new(1, -40, 0, -6);
	MenuIconHolder.Position = UDim2.new(0, 2, 0, -6);

	-- Chat
	if (Chat) then
		SetupChat();
	else
		BackpackButton.Position = UDim2.fromOffset(4, 0);
	end

	-- Style game icons
	Spawn(WatchGameIcons);

	-- Connections
	Connect(Changed(RobloxMenu, "BackgroundTransparency"), function()
		RobloxMenu.BackgroundTransparency = 1
	end)

	Connect(ExperienceChatApp.ChildAdded, function(Object)
		if (Object.Name == "chatWindow") then
			SetupChat();
		end
	end)

	Connect(ChatHolder.ChildRemoved, function(Object)
		if (Object.Name == "chat") then
			BackpackButton.Position = UDim2.fromOffset(4, 0);
		end
	end)

	Connect(Changed(Inventory, "Visible"), function()
		BackpackIconSystem(GetImage("Backpack", Inventory.Visible));
	end)

	Connect(Changed(Menu, "Visible"), function()
		RobloxIconSystem(GetImage("Menu", Menu.Visible));
	end)

	Connect(CoreGui.ChildAdded, function(Object)
		if (Object.Name == "TooltipLayer" and Object:IsA("ScreenGui")) then
			Object.Enabled = false
		end
	end)

	-- Icons
	RobloxIconSystem(GetImage("Menu", Menu.Visible));
	BackpackIconSystem(GetImage("Backpack", Inventory.Visible));
end

-- creates the top right info (account name, account age, health)
local AccountContainer = function(Parent)
	local LeaderstatColumns = {}
	local TotalWidth = 170

	local UpdateAccountSize = function()
		LeaderstatColumns = {}
		local Stats = LocalPlayer:FindFirstChild("leaderstats")

		if (Stats) then
			for _, Stat in next, Stats:GetChildren() do
				if (Stat:IsA("IntValue") or Stat:IsA("NumberValue") or Stat:IsA("StringValue")) then
					Insert(LeaderstatColumns, Stat.Name)
				end
			end
		end

		TotalWidth = 170 + (#LeaderstatColumns * 60)
	end

	UpdateAccountSize()

	local AccountInfo = Create("ImageButton", {
		Position = UDim2.new(1, -TotalWidth, 0, 0),
		Size = UDim2.new(0, TotalWidth, 0, 35),
		Parent = Parent,
		BackgroundTransparency = 1,
	})

	local HealthContainer = Create("Frame", {
		BackgroundColor3 =  Color3.fromRGB(228, 236, 246),
		Position = UDim2.new(0, 7, 1, -7),
		Size = UDim2.new(0, 156, 0, 3),
		Parent = AccountInfo,
		BorderSizePixel = 0,
	})

	local HealthFill = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(27, 252, 107),
		Size = UDim2.fromScale(1, 1),
		Parent = HealthContainer,
		BorderSizePixel = 0,
	})

	local IgnorePaddingFrame = Create("Frame", {
		Parent = AccountInfo,
		Name = "IgnorePaddingFrame",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	})

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(0, 156, 0, 18),
		Parent = AccountInfo,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = LocalPlayer.Name,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	})

	local AccountAgeLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 13),
		Size = UDim2.new(0, 156, 0, 12),
		Parent = AccountInfo,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "Account: ...",
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	})

	Spawn(function()
		local Under = IsUnder13(LocalPlayer);
		AccountAgeLabel.Text = Under and "Account: <13" or "Account: 13+"
	end)

	local StatHeaderLabels = {}
	local StatValueLabels = {}

	local UpdateAccountStats = function()
		for _, Label in next, StatHeaderLabels do
			Destroy(Label);
		end

		for _, Label in next, StatValueLabels do
			Destroy(Label);
		end

		UpdateAccountSize();
		AccountInfo.Size = UDim2.new(0, TotalWidth, 0, 35);
		AccountInfo.Position = UDim2.new(1, -TotalWidth, 0, 0);
		StatHeaderLabels = ({});
		StatValueLabels = ({});

		local Stats = LocalPlayer:FindFirstChild("leaderstats");

		if (Stats) then
			for Index, StatName in next, LeaderstatColumns do
				local Stat = Stats:FindFirstChild(StatName);

				if (Stat) then
					local StatHeaderLabel = Create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 170 + ((Index - 1) * 60), 0, 1),
						Size = UDim2.new(0, 60, 0, 18),
						Parent = IgnorePaddingFrame,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Text = StatName,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					})

					local StatValueLabel = Create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 170 + ((Index - 1) * 60), 0, 17),
						Size = UDim2.new(0, 60, 0, 12),
						Parent = IgnorePaddingFrame,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Text = FormatNumber(Stat.Value),
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					})

					Insert(StatHeaderLabels, StatHeaderLabel);
					Insert(StatValueLabels, StatValueLabel);
					Connect(Stat.Changed, function(Value)
						StatValueLabel.Text = FormatNumber(Value);
					end)
				end
			end
		end
	end

	local UpdateHealthGui = function(Health: number, MaxHealth: number)
		HealthFill.Size = UDim2.fromScale(Health / MaxHealth, 1);

		if (Health < MaxHealth) and (Health > MaxHealth / 2) then
			HealthFill.BackgroundColor3 = Color3.new(1 - (Health / MaxHealth) + 0.5, 1, 0);
		else
			HealthFill.BackgroundColor3 = Color3.fromRGB(27, 252, 107);
		end

		if (Health == MaxHealth / 2) then
			HealthFill.BackgroundColor3 = Color3.new(1, 1, 0);
		end

		if (Health < MaxHealth / 2) then
			HealthFill.BackgroundColor3 = Color3.new(1, (Health/MaxHealth) * 2, 0);
		end 
	end

	local UpdateHealth = function()
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
		local Humanoid = Character:WaitForChild("Humanoid");

		if (Humanoid) then
			UpdateHealthGui(Humanoid.Health, Humanoid.MaxHealth);
			Connect(Changed(Humanoid, "Health"), function()
				UpdateHealthGui(Humanoid.Health, Humanoid.MaxHealth);
			end)
		end
	end

	Spawn(function()
		UpdateHealth();
		Connect(LocalPlayer.CharacterAdded, UpdateHealth);
	end)

	Connect(LocalPlayer.ChildAdded, function(Child)
		if (Child.Name == "leaderstats") then
			Wait(0.1); UpdateAccountStats();
			Connect(Child.ChildAdded, function()
				Wait(0.1); UpdateAccountStats();
			end)
		end
	end)

	UpdateAccountStats();

	return AccountInfo
end

-- Setup
local TopbarBackground, AccountInfo

if (not Core2016) then
	local CustomScreenGui = Create("ScreenGui", {
		Name = "Project2016RobloxGui",
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	Insert(Core2016Data.Objects, CustomScreenGui);

	TopbarBackground = Create("Frame", {
		Parent = CustomScreenGui,
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(31, 31, 31),
	})

	AccountInfo = AccountContainer(TopbarBackground);

	GameIconHolder = Create("Frame", {
		Parent = TopbarBackground,
		Name = "GameIcons",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 160, 0, -6),
		Size = UDim2.new(0, 400, 0, 44),
		ClipsDescendants = false,
	})

	Create("UIListLayout", {
		Parent = GameIconHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	Spawn(function()
		Wait(1);
		local FindRightmost = function()
			local RightEdge = 0
			local RightIcon = nil

			for _, Child in next, ChatHolder:GetChildren() do
				if (Child:IsA("Frame") and Child.Visible) then
					local Edge = Child.AbsolutePosition.X + Child.AbsoluteSize.X
					if (Edge > RightEdge) then
						RightEdge = Edge
						RightIcon = Child
					end
				end
			end

			return RightIcon
		end

		local UpdateIconPos = function()
			local LastIcon = FindRightmost();
			if (LastIcon) then
				local X = LastIcon.AbsolutePosition.X + LastIcon.AbsoluteSize.X
				local Y = LastIcon.AbsolutePosition.Y - TopbarBackground.AbsolutePosition.Y
				GameIconHolder.Position = UDim2.fromOffset(X, Y);
			end
		end

		UpdateIconPos();

		Connect(ChatHolder.ChildAdded, function() Wait(0.2); UpdateIconPos(); end)
		Connect(ChatHolder.ChildRemoved, function() Wait(0.2); UpdateIconPos(); end)

		for _, Child in next, ChatHolder:GetChildren() do
			if (Child:IsA("Frame")) then
				pcall(function()
					Connect(Changed(Child, "Visible"), function() UpdateIconPos(); end)
					Connect(Changed(Child, "AbsolutePosition"), function() UpdateIconPos(); end)
				end)
			end
		end
	end)
end

getgenv().Core2016 = true
Spawn(Redesign);

if (Configuration.OldGraphics) then

	for _, Object in next, Lighting:GetChildren() do
		if (Discover({ "DepthOfFieldEffect", "SunRaysEffect", "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "Atmosphere" }, Object.ClassName)) then
			Destroy(Object);
		end
	end

	Create("ColorCorrectionEffect", {
		Parent = Lighting,
		Saturation = 0,
		Contrast = -0.1,
	})

	if (sethiddenproperty) then
		sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility);
        sethiddenproperty(Lighting, "GlobalShadows", false)
    end
end

if (Configuration.HideVoiceChatButton) then
	Spawn(function()
		ChatHolder:WaitForChild("toggle_mic_mute", 1000).Visible = false
	end)
end

if (Configuration.OldConsole) then
	Spawn(function()
		local Success, Error = pcall(function()
			LoadProjectModule("console");
		end)

		if (not Success) then
			warn("[Core2016] Failed to load OldConsole:", Error);
		end
	end)
end

if (Configuration.OldEscapeMenu) then
	Spawn(function()
		local Success, Error = pcall(function()
			LoadProjectModule("settings");
		end)
		if (not Success) then
			warn("[Core2016] Failed to load OldEscapeMenu:", Error);
		end
	end)
end

if (Configuration.OldBubbleChat) then
	local BubbleChat = TextChatService:WaitForChild("BubbleChatConfiguration");

	BubbleChat.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	BubbleChat.TextSize = 23
	BubbleChat.BackgroundTransparency = 0
	BubbleChat.TextColor3 = Color3.fromRGB(27, 42, 53);
	BubbleChat.BackgroundColor3 = Color3.fromRGB(255, 255, 255);

	Spawn(function()
		local CornerRadius, UIPadding = BubbleChat:FindFirstChild("UICorner") or Create("UICorner", {
			Parent = BubbleChat,
			CornerRadius = UDim.new(0, 4),
		}), BubbleChat:FindFirstChild("UIPadding") or Create("UIPadding", {
			Parent = BubbleChat,
		});

		if (CornerRadius) then
			CornerRadius.CornerRadius = UDim.new(0, 5);
		end

		if (UIPadding) then
			for _, Property in next, ({ "PaddingTop", "PaddingBottom", "PaddingRight", "PaddingLeft" }) do
				UIPadding[Property] = UDim.new(0, 6);
			end
		end
	end)
end

if (Configuration.OldPlayerList) then
	-- Info
	local BuildersClub = ({ "rbxassetid://7038283888", "rbxassetid://7038284499", "rbxassetid://7038285281" });
	local TeamFrames = ({});
	local LeaderstatColumns = ({});
	local PlayerUpdateFunctions = ({});
	local TotalWidth = 170
	local ControlWidth = 157
	local ActivePlayerObject = nil
	local ActivePlayerControls = nil

	local GetSize = function(X: number)
		local Viewport = workspace.CurrentCamera.ViewportSize
		return UDim2.new(0, X, 0, Clamp(Viewport.Y / 2.5, 250, 416))
	end

	-- Connections
	Connect(RunService.RenderStepped, function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
		pcall(function()
			TopBarApp.UnibarLeftFrame.HealthBar.HealthBar.Visible = false
		end)
	end)

	-- Objects
	local PlayerListContainer = Create("Frame", {
		Name = "PlayerListContainer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 1, 5),
		Parent = TopbarBackground,
		Size = GetSize(170),
	})

	local SetPlayerListWidth = function(Width)
		PlayerListContainer.Size = GetSize(Width);
	end

	local ScrollList = Create("ScrollingFrame", {
		Name = "ScrollList",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = PlayerListContainer,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})

	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 2),
		Parent = ScrollList,
	})

	local UpdateLeaderstats = function()
		LeaderstatColumns = ({});
		local Stats = LocalPlayer:FindFirstChild("leaderstats");

		if (Stats) then
			for _, Stat in next, Stats:GetChildren() do
				if (Stat:IsA("IntValue") or Stat:IsA("NumberValue") or Stat:IsA("StringValue")) then
					Insert(LeaderstatColumns, Stat.Name);
				end
			end
		end

		TotalWidth = 170 + (#LeaderstatColumns * 60);
		SetPlayerListWidth(TotalWidth);

		for _, Data in next, TeamFrames do
			local HeaderIgnorePaddingFrame = Data.Header:FindFirstChild("HeaderIgnorePaddingFrame");
			Data.Header.Size = UDim2.new(0, TotalWidth, 0, 20);

			if (HeaderIgnorePaddingFrame) then
				for _, Child in next, HeaderIgnorePaddingFrame:GetChildren() do
					if (Child:IsA("TextLabel")) then
						Destroy(Child);
					end
				end
			end
		end
	end

	local CreateTeamFrame = function(Team)
		local TeamKey = (Team or "Neutral");
		local TeamStatLabels = ({});
		local TeamFrameKey = TeamFrames[TeamKey]

		if (TeamFrameKey) then
			return (TeamFrameKey);
		end

		local TeamFrame = Create("Frame", {
			Parent = ScrollList,
			Name = (Team and Team.Name) or "Neutral",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = (Team == nil and 999) or 0,
			AutomaticSize = Enum.AutomaticSize.Y,
		})

		local TeamHeader = Create("TextButton", {
			Parent = TeamFrame,
			Name = "TeamHeader",
			BackgroundColor3 = Team and Team.TeamColor.Color or Color3.fromRGB(75, 75, 75),
			BackgroundTransparency = 0.500,
			BorderSizePixel = 0,
			Size = UDim2.new(0, TotalWidth, 0, 20),
			AutoButtonColor = false,
			TextSize = 14,
			Font = Enum.Font.SourceSansBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			Text = (Team and Team.Name) or "Neutral",
		})

		Create("UIPadding", {
			Parent = TeamHeader,
			PaddingLeft = UDim.new(0, 5),
		})

		local HeaderIgnorePaddingFrame = Create("Frame", {
			Parent = TeamHeader,
			Name = "HeaderIgnorePaddingFrame",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		})

		local PlayerContainer = Create("Frame", {
			Parent = TeamFrame,
			Name = "PlayerContainer",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.fromOffset(0, 21),
			AutomaticSize = Enum.AutomaticSize.Y,
		})

		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 2),
			Parent = PlayerContainer,
		})

		local UpdateTeamStats = function()
			for _, Label in next, TeamStatLabels do
				Destroy(Label);
			end

			TeamStatLabels = ({});
			for Index, StatName in next, LeaderstatColumns do
				local TotalValue = 0
				local IntValue = true

				for _, PlayerObject in next, PlayerContainer:GetChildren() do
					if (PlayerObject:IsA("TextButton")) then
						local Player = Players:FindFirstChild(PlayerObject.Name);

						if (Player) then
							local Stats = Player:FindFirstChild("leaderstats");

							if (Stats) then
								local Stat = Stats:FindFirstChild(StatName);

								if (Stat) then
									if (Stat:IsA("NumberValue")) then
										IntValue = false
									end

									TotalValue = TotalValue + (tonumber(Stat.Value) or 0);
								end
							end
						end
					end
				end

				local StatLabel = Create("TextLabel", {
					Parent = HeaderIgnorePaddingFrame,
					Name = StatName .. "Total",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 170 + ((Index - 1) * 60) - 5, 0, 0),
					Size = UDim2.new(0, 60, 1, 0),
					TextSize = 14,
					Font = Enum.Font.SourceSansBold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = FormatNumber(TotalValue),
				})

				Insert(TeamStatLabels, StatLabel);
			end
		end

		UpdateTeamStats();
		TeamFrames[TeamKey] = ({ 
			Frame = TeamFrame, 
			Container = PlayerContainer, 
			Header = TeamHeader, 
			UpdateTeamStats = UpdateTeamStats
		})

		return TeamFrames[TeamKey]
	end

	local UpdatePlayerOrder = function(Player)
		local TeamKey = (Player.Team or "Neutral");
		local TeamData = TeamFrames[TeamKey]

		if (not TeamData) then
			return
		end

		for _, PlayerObject in next, TeamData.Container:GetChildren() do
			if (PlayerObject:IsA("TextButton") and Players:FindFirstChild(PlayerObject.Name)) then
				local TargetPlayer = Players:FindFirstChild(PlayerObject.Name);
				local LayoutOrder = 0

				if (#LeaderstatColumns > 0) then
					local Stats = TargetPlayer:FindFirstChild("leaderstats");
					local FirstStat = Stats and Stats:FindFirstChild(LeaderstatColumns[1]);

					if (FirstStat and (FirstStat:IsA("IntValue") or FirstStat:IsA("NumberValue"))) then
						LayoutOrder = -tonumber(FirstStat.Value) or 0
					end
				end

				PlayerObject.LayoutOrder = LayoutOrder
			end
		end
	end

	local AddPlayer = function(Player)
		local CurrentTeamKey = nil
		local PlayerObject

		local CloseControls = function()
			if (ActivePlayerControls) then
				Destroy(ActivePlayerControls);
				ActivePlayerControls = nil
			end

			if (ActivePlayerObject) then
				ActivePlayerObject.BackgroundColor3 = Color3.fromRGB(31, 31, 31);
				ActivePlayerObject = nil
			end

			SetPlayerListWidth(TotalWidth);
		end

		local FocusPlayer = function(Button)
			pcall(function()
				local Character = Player.Character
				local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid");
				local Camera = workspace.CurrentCamera

				if (Humanoid and Camera) then
					Camera.CameraSubject = Humanoid
				end
			end)

			if (Button) then
				Button.Text = "Following"
			end
		end

		local CreateControlButton = function(Parent, Text, Icon, LayoutOrder, Clicked)
			local Button = Create("TextButton", {
				Parent = Parent,
				BackgroundColor3 = Color3.fromRGB(31, 31, 31),
				BackgroundTransparency = 0.500,
				BorderSizePixel = 0,
				Size = UDim2.new(0, ControlWidth, 0, 24),
				AutoButtonColor = true,
				TextSize = 14,
				Font = Enum.Font.SourceSans,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = Text,
				LayoutOrder = LayoutOrder,
			})

			Create("UIPadding", {
				Parent = Button,
				PaddingLeft = UDim.new(0, 34),
			})

			if (Icon) then
				Create("ImageLabel", {
					Parent = Button,
					BackgroundTransparency = 1,
					Image = Icon,
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(0, 8, 0.5, -8),
				})
			end

			Connect(Button.MouseEnter, function()
				Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70);
			end)

			Connect(Button.MouseLeave, function()
				Button.BackgroundColor3 = Color3.fromRGB(31, 31, 31);
			end)

			if (Clicked) then
				Connect(Button.MouseButton1Click, function()
					Clicked(Button);
				end)
			end

			return Button
		end

		local UpdatePlayerTeam = function()
			local TeamKey = (Player.Team or "Neutral");
			local TeamFrame = TeamFrames[CurrentTeamKey]

			if (CurrentTeamKey == TeamKey) then
				return
			end

			if (CurrentTeamKey and TeamFrame and TeamFrame.UpdateTeamStats) then
				TeamFrame.UpdateTeamStats();
			end

			CurrentTeamKey = TeamKey

			local TeamData = CreateTeamFrame(TeamKey)
			PlayerObject.Parent = TeamData.Container
			UpdatePlayerOrder(Player);

			if (TeamData and TeamData.UpdateTeamStats) then
				TeamData.UpdateTeamStats();
			end
		end

		local TeamKey = (Player.Team or "Neutral");
		local TeamData = CreateTeamFrame(TeamKey)

		CurrentTeamKey = TeamKey
		PlayerObject = Create("TextButton", {
			Parent = TeamData.Container,
			Name = Player.Name,
			BackgroundColor3 = Color3.fromRGB(31, 31, 31),
			BackgroundTransparency = 0.500,
			BorderSizePixel = 0,
			Size = UDim2.new(0, TotalWidth, 0, 24),
			AutoButtonColor = false,
			TextSize = 14,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Text = Player.Name,
		})

		local IgnorePaddingFrame = Create("Frame", {
			Parent = PlayerObject,
			Name = "IgnorePaddingFrame",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		})

		local Icon = Create("ImageLabel", {
			Parent = IgnorePaddingFrame,
			Name = "Icon",
			BackgroundTransparency = 1.000,
			BorderSizePixel = 0,
			Position = UDim2.new(0, -19, 0.02, 4),
			Size = UDim2.new(0, 16, 0, 16),
		})

		Spawn(function()
			if (Player:IsFriendsWith(LocalPlayer.UserId)) then
				Icon.Image = "rbxasset://textures/ui/icon_friends_16.png"
			elseif (Player.UserId == game.CreatorId) then
				Icon.Image = "rbxasset://textures/ui/icon_placeowner.png"
			elseif (Player.MembershipType == Enum.MembershipType.Premium) then
				Icon.Image = BuildersClub[Random(1, #BuildersClub)]
			end
		end)

		Create("UIPadding", {
			Parent = PlayerObject,
			PaddingLeft = UDim.new(0, 23),
		})

		local StatLabels = {}
		local UpdateStats = function()
			for _, Label in next, StatLabels do
				Destroy(Label);
			end

			StatLabels = ({});

			local Stats = Player:FindFirstChild("leaderstats");

			if (Stats) then
				for Index, StatName in next, LeaderstatColumns do
					local Stat = Stats:FindFirstChild(StatName);

					if (Stat) then
						local StatLabel = Create("TextLabel", {
							Parent = IgnorePaddingFrame,
							Name = StatName,
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 170 + ((Index - 1) * 60) - 23, 0, 0),
							Size = UDim2.new(0, 60, 1, 0),
							TextSize = 14,
							Font = Enum.Font.SourceSans,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							Text = FormatNumber(Stat.Value),
						})

						Insert(StatLabels, StatLabel)
						Connect(Stat.Changed, function(Value)
							StatLabel.Text = FormatNumber(Stat.Value);

							local TeamKey = (Player.Team or "Neutral");
							local TeamFrame = TeamFrames[TeamKey]

							if (TeamFrame and TeamFrame.UpdateTeamStats) then
								TeamFrame.UpdateTeamStats();
							end

							if (Index == 1) then
								UpdatePlayerOrder(Player);
							end
						end)
					end
				end
			end

			local TeamKey = (Player.Team or "Neutral");
			local TeamFrame = TeamFrames[TeamKey]

			if (TeamFrame and TeamFrame.UpdateTeamStats) then
				TeamFrame.UpdateTeamStats();
			end

			UpdatePlayerOrder(Player);
		end

		UpdateStats();
		PlayerUpdateFunctions[Player] = UpdateStats

		Connect(Player.ChildAdded, function(Child)
			if (Child.Name == "leaderstats") then
				Wait(0.1); UpdateStats();
			end
		end)

		Connect(Changed(Player, "Team"), UpdatePlayerTeam);

		Connect(PlayerObject.MouseEnter, function()
			if (PlayerObject ~= ActivePlayerObject) then
				PlayerObject.BackgroundColor3 = Color3.fromRGB(55, 55, 55);
			end
		end)

		Connect(PlayerObject.MouseLeave, function()
			if (PlayerObject ~= ActivePlayerObject) then
				PlayerObject.BackgroundColor3 = Color3.fromRGB(31, 31, 31);
			end
		end)

		Connect(PlayerObject.MouseButton1Click, function()
			local WasOpen = (ActivePlayerObject == PlayerObject)

			if (not WasOpen) then
				CloseControls();

				local PlayerControlsHolder = Create("Frame", {
					Parent = PlayerObject,
					Name = "PlayerControlsHolder",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, -ControlWidth - 2, 0, 0),
					Visible = true,
				})

				Create("UIListLayout", {
					Parent = PlayerControlsHolder,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 2),
				})

				local FriendClicked = function(Button)
					LocalPlayer:RequestFriendship(Player);
					Button.Text = "Request sent"
				end

				local ReportClicked = function()
					local Env = getgenv();

					if (Env.Settings2016 and Env.Settings2016.ReportPlayer) then
						Env.Settings2016.ReportPlayer(Env.Settings2016, Player);
					end
				end

				CreateControlButton(PlayerControlsHolder, "View", "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png", 1, FocusPlayer);
				CreateControlButton(PlayerControlsHolder, "Follow", "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png", 2, FocusPlayer);
				CreateControlButton(PlayerControlsHolder, "Add Friend", "rbxasset://textures/ui/icon_friends_16.png", 3, FriendClicked);
				CreateControlButton(PlayerControlsHolder, "Report abuse", "rbxasset://textures/ui/Settings/MenuBarIcons/ReportAbuseTab.png", 4, ReportClicked);

				ActivePlayerObject = PlayerObject
				ActivePlayerControls = PlayerControlsHolder
				PlayerObject.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
			else
				CloseControls();
			end

			SetPlayerListWidth((not WasOpen and (TotalWidth + ControlWidth)) or TotalWidth);
		end)

		Defer(function()
			local TeamKey = (Player.Team or "Neutral");
			local TeamFrame = TeamFrames[TeamKey]

			if (TeamFrame and TeamFrame.UpdateTeamStats) then
				TeamFrame.UpdateTeamStats();
			end
		end)
	end

	UpdateLeaderstats();

	for _, Team in next, Teams:GetTeams() do
		CreateTeamFrame(Team);
	end

	CreateTeamFrame(nil);

	for _, Player in next, Players:GetPlayers() do
		AddPlayer(Player);
	end

	-- Connections
	Connect(Players.PlayerAdded, function(Player)
		AddPlayer(Player);
	end)

	Connect(Players.PlayerRemoving, function(Player)
		PlayerUpdateFunctions[Player] = nil

		if (ActivePlayerObject and ActivePlayerObject.Name == Player.Name) then
			ActivePlayerObject = nil
			ActivePlayerControls = nil
			SetPlayerListWidth(TotalWidth);
		end

		for _, Data in next, TeamFrames do
			for _, User in next, Data.Container:GetChildren() do
				if (User.Name == Player.Name) then
					Destroy(User);
				end
			end
		end
	end)

	Connect(Teams.ChildAdded, function(Team)
		CreateTeamFrame(Team);
	end)

	Connect(Teams.ChildRemoved, function(Team)
		local TeamFrame = TeamFrames[Team]

		if (TeamFrame) then
			Destroy(TeamFrame.Frame);
			TeamFrames[Team] = nil
		end
	end)

	Connect(LocalPlayer.ChildAdded, function(Child)
		if (Child.Name == "leaderstats") then
			Wait(0.1); UpdateLeaderstats();

			for _, Data in next, TeamFrames do
				for _, PlayerObject in next, Data.Container:GetChildren() do
					if (PlayerObject:IsA("TextButton")) then
						PlayerObject.Size = UDim2.new(0, TotalWidth, 0, 24)
					end
				end
			end

			for Player, Update in next, PlayerUpdateFunctions do
				Update();
			end

			Connect(Child.ChildAdded, function(Stat)
				if (Stat:IsA("IntValue") or Stat:IsA("NumberValue") or Stat:IsA("StringValue")) then
					Wait(0.1); UpdateLeaderstats();

					for _, Data in next, TeamFrames do
						for _, PlayerObject in next, Data.Container:GetChildren() do
							if (PlayerObject:IsA("TextButton")) then
								PlayerObject.Size = UDim2.new(0, TotalWidth, 0, 24);
							end
						end
					end

					for Player, Update in next, PlayerUpdateFunctions do
						Update();
					end
				end
			end)
		end
	end)

	Connect(UserInputService.InputBegan, function(Input, Processed)
		if (Input.KeyCode == Enum.KeyCode.Tab) then
			PlayerListContainer.Visible = (not PlayerListContainer.Visible);
		end
	end)

	if (AccountInfo) then
		Connect(AccountInfo.MouseButton1Click, function()
			PlayerListContainer.Visible = (not PlayerListContainer.Visible);
		end)
	end
end

if (Configuration.FPSCounter and TopbarBackground) then
	local FPSLabel = Create("TextLabel", {
		Name = "FPSCounter",
		Parent = TopbarBackground,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 60, 1, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "FPS: 0",
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	})

	local FrameTimes = {}
	local FrameIndex = 0
	local FrameCount = 30
	local FPS = 0

	for i = 1, FrameCount do FrameTimes[i] = 0 end

	Connect(RunService.RenderStepped, function(DeltaTime)
		FrameIndex = (FrameIndex % FrameCount) + 1
		FrameTimes[FrameIndex] = DeltaTime
	end)

	Spawn(function()
		while true do
			Wait(0.5);
			local Total = 0
			for i = 1, FrameCount do Total += FrameTimes[i] end
			if (Total > 0) then
				FPS = Floor(FrameCount / Total)
			end
			FPSLabel.Text = Format("FPS: %d", FPS);
		end
	end)
end

if (Configuration.OldStudTextures) then
	local ApplyStuds = function(Part)
		if (Part:IsA("BasePart") and Part.Material == Enum.Material.Plastic and Part.TopSurface == Enum.SurfaceType.Studs) then
			if (not Part:FindFirstChildOfClass("Texture")) then
				Create("Texture", {
					Parent = Part,
					Face = Enum.NormalId.Top,
					Texture = "rbxassetid://7027211371",
					Color3 = Color3.new(Clamp(Part.Color.R * 2, 0, 1), Clamp(Part.Color.G * 2, 0, 1), Clamp(Part.Color.B * 2, 0, 1)),
					Transparency = Part.Transparency,
				})
			end
		end
	end

	for _, Object in next, workspace:GetDescendants() do
		ApplyStuds(Object);
	end

	Connect(workspace.DescendantAdded, ApplyStuds);
end

if (Configuration.OldCursor) then
	local Mouse = LocalPlayer:GetMouse()
	Mouse.Icon = "rbxasset://textures/ArrowFarCursor.png"
end
