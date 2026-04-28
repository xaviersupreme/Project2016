local CoreGui = game:GetService("CoreGui");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");
local StarterGui = game:GetService("StarterGui");
local SoundService = game:GetService("SoundService");
local Players = game:GetService("Players");

local LocalPlayer = Players.LocalPlayer
local GameSettings = UserSettings().GameSettings
local RenderingSettings = settings().Rendering

local Spawn, Wait = task.spawn, task.wait
local Insert, Remove = table.insert, table.remove
local Clamp, Floor = math.clamp, math.floor

local SETTINGS_SHIELD_COLOR = Color3.new(41/255, 41/255, 41/255);
local SETTINGS_SHIELD_TRANSPARENCY = 0.2
local SETTINGS_BASE_ZINDEX = 200
local SETTINGS_INACTIVE_POSITION = UDim2.new(0, 0, -1, -36);
local SETTINGS_ACTIVE_POSITION = UDim2.new(0, 0, 0, 0);
local ROW_CONTROL_X = 430

local BUTTON_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png";
local BUTTON_SELECTED_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png";
local TAB_BAR_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuBackground.png";
local TAB_SELECTION_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuSelection.png";
local DROP_DOWN_IMAGE = "rbxasset://textures/ui/Settings/DropDown/DropDown.png";
local PLAYER_LIST_OFFSET = 0

if (getgenv().Settings2016Data) then
	for _, Connection in next, (getgenv().Settings2016Data.Connections or {}) do
		pcall(function()
			Connection:Disconnect();
		end)
	end

	for _, Object in next, (getgenv().Settings2016Data.Objects or {}) do
		pcall(function()
			Object:Destroy();
		end)
	end
end

local Data = ({
	Connections = ({}),
	Objects = ({}),
})
getgenv().Settings2016Data = Data

for _, Object in next, CoreGui:GetChildren() do
	if (Object.Name == "Settings2016Gui" or Object.Name == "Core2016SettingsGui") then
		Object:Destroy();
	end
end

local Connect = function(Signal, Callback)
	local Connection = Signal:Connect(Callback);
	Insert(Data.Connections, Connection);
	return Connection
end

local Create = function(Class: string, Properties: { [string]: any })
	local Object = Instance.new(Class);

	for Property, Value in next, (Properties or {}) do
		Object[Property] = Value
	end

	return Object
end

local Protect = function(Callback)
	local Success, Error = pcall(Callback);

	if (not Success) then
		warn("[Settings2016]", Error);
	end

	return Success
end

local FadeText = function(Label, Transparency)
	Spawn(function()
		local Start = Label.TextTransparency

		for Index = 1, 6 do
			if (not Label.Parent) then
				return
			end

			Label.TextTransparency = Start + ((Transparency - Start) * (Index / 6));
			Wait();
		end
	end)
end

local LerpUDim = function(Start, Goal, Alpha)
	return UDim.new(Start.Scale + ((Goal.Scale - Start.Scale) * Alpha), Start.Offset + ((Goal.Offset - Start.Offset) * Alpha));
end

local LerpUDim2 = function(Start, Goal, Alpha)
	return UDim2.new(LerpUDim(Start.X, Goal.X, Alpha), LerpUDim(Start.Y, Goal.Y, Alpha));
end

local LerpColor = function(Start, Goal, Alpha)
	return Color3.new(Start.R + ((Goal.R - Start.R) * Alpha), Start.G + ((Goal.G - Start.G) * Alpha), Start.B + ((Goal.B - Start.B) * Alpha));
end

local MoveTweens = ({})
local MoveTo = function(Object, Position, Callback, Frames)
	MoveTweens[Object] = (MoveTweens[Object] or 0) + 1
	local Id = MoveTweens[Object]

	Spawn(function()
		local Start = Object.Position
		Frames = Frames or 8

		for Index = 1, Frames do
			if (not Object.Parent or MoveTweens[Object] ~= Id) then
				return
			end

			local Alpha = Index / Frames
			Alpha = 1 - ((1 - Alpha) * (1 - Alpha));
			Object.Position = LerpUDim2(Start, Position, Alpha);
			Wait();
		end

		Object.Position = Position

		if (Callback and MoveTweens[Object] == Id) then
			Callback();
		end
	end)
end

local ColorTweens = ({})
local ColorTo = function(Object, Color)
	ColorTweens[Object] = (ColorTweens[Object] or 0) + 1
	local Id = ColorTweens[Object]

	Spawn(function()
		local Start = Object.BackgroundColor3

		for Index = 1, 5 do
			if (not Object.Parent or ColorTweens[Object] ~= Id) then
				return
			end

			Object.BackgroundColor3 = LerpColor(Start, Color, Index / 5);
			Wait();
		end
	end)
end

local SetMouseSensitivity = function(Value)
	Protect(function()
		UserSettings().GameSettings.MouseSensitivity = Value;
	end)

	Protect(function()
		UserInputService.MouseDeltaSensitivity = Value;
	end)
end

local SetMasterVolume = function(Value)
	Protect(function()
		UserSettings().GameSettings.MasterVolume = Value;
	end)

	Protect(function()
		SoundService.Volume = Value;
	end)
end

local ScreenGui = Create("ScreenGui", {
	Name = "Settings2016Gui",
	Parent = CoreGui,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9000,
	Enabled = true,
})
Insert(Data.Objects, ScreenGui);

local MakeText = function(Parent, Text, Size, Position)
	return Create("TextLabel", {
		Parent = Parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = Size,
		Position = Position or UDim2.new(),
		Font = Enum.Font.SourceSansBold,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		Text = Text,
		TextWrapped = true,
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})
end

local ButtonHome = ({})
local MakeStyledButton = function(Name, Text, Size, Clicked)
	local Button = Create("ImageButton", {
		Name = Name,
		Image = BUTTON_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 6, 46, 44),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = Size,
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	local Label = Create("TextLabel", {
		Name = Name .. "TextLabel",
		Parent = Button,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -8),
		Position = UDim2.new(0, 0, 0, 0),
		Font = Enum.Font.SourceSansBold,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		Text = Text,
		TextWrapped = true,
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})
	ButtonHome[Label] = Label.Position

	Connect(Button.MouseEnter, function()
		Button.Image = BUTTON_SELECTED_IMAGE;
		local Position = ButtonHome[Label] or Label.Position
		MoveTo(Label, UDim2.new(Position.X.Scale, Position.X.Offset, Position.Y.Scale, Position.Y.Offset - 2));
	end)

	Connect(Button.MouseLeave, function()
		Button.Image = BUTTON_IMAGE;
		MoveTo(Label, ButtonHome[Label] or UDim2.new(0, 0, 0, 0));
	end)

	Connect(Button.MouseButton1Down, function()
		local Position = ButtonHome[Label] or Label.Position
		MoveTo(Label, UDim2.new(Position.X.Scale, Position.X.Offset, Position.Y.Scale, Position.Y.Offset + 2));
	end)

	if (Clicked) then
		Connect(Button.MouseButton1Click, Clicked);
	end

	return Button, Label
end

local MakePage = function(Name)
	local Page = ({
		Name = Name,
		Rows = ({}),
		Frame = Create("Frame", {
			Name = Name .. "Page",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			ZIndex = SETTINGS_BASE_ZINDEX + 1,
		}),
	})

	function Page:AddRow(Row)
		Row.Parent = self.Frame
		Row.Position = UDim2.new(0, 0, 0, #self.Rows * 50);
		Insert(self.Rows, Row);
		self.Frame.Size = UDim2.new(1, 0, 0, #self.Rows * 50);
	end

	return Page
end

local Hub = ({
	Visible = false,
	Pages = ({}),
	MenuStack = ({}),
	CurrentPage = nil,
	NativeMenuTarget = nil,
})

local ClippingShield = Create("Frame", {
	Name = "SettingsShield",
	Parent = ScreenGui,
	Size = UDim2.new(1, 0, 1, 0),
	Position = SETTINGS_ACTIVE_POSITION,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = SETTINGS_BASE_ZINDEX,
})

Hub.Shield = Create("Frame", {
	Name = "SettingsShield",
	Parent = ClippingShield,
	Size = UDim2.new(1, 0, 1, 0),
	Position = SETTINGS_INACTIVE_POSITION,
	BackgroundColor3 = SETTINGS_SHIELD_COLOR,
	BackgroundTransparency = SETTINGS_SHIELD_TRANSPARENCY,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = SETTINGS_BASE_ZINDEX,
})

Hub.Modal = Create("TextButton", {
	Name = "Modal",
	Parent = Hub.Shield,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	Modal = true,
	ZIndex = SETTINGS_BASE_ZINDEX,
})

Hub.HubBar = Create("ImageLabel", {
	Name = "HubBar",
	Parent = Hub.Shield,
	Image = TAB_BAR_IMAGE,
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(4, 4, 6, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 800, 0, 60),
	Position = UDim2.new(0.5, -400, 0.1, 0),
	ZIndex = SETTINGS_BASE_ZINDEX + 1,
})

Hub.PageClipper = Create("Frame", {
	Name = "PageViewClipper",
	Parent = Hub.Shield,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Size = UDim2.new(0, 800, 0, 420),
	Position = UDim2.new(0.5, -400, 0.1, 61),
	ZIndex = SETTINGS_BASE_ZINDEX + 1,
})

Hub.PageView = Create("ScrollingFrame", {
	Name = "PageView",
	Parent = Hub.PageClipper,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, 0),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 6,
	ZIndex = SETTINGS_BASE_ZINDEX + 1,
})

Hub.BottomButtonFrame = Create("Frame", {
	Name = "BottomButtonFrame",
	Parent = Hub.Shield,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 800, 0, 60),
	Position = UDim2.new(0.5, -400, 0.9, -60),
	ZIndex = SETTINGS_BASE_ZINDEX + 1,
})

local ResizeHub = function()
	local Viewport = ScreenGui.AbsoluteSize

	if (Viewport.X <= 0 or Viewport.Y <= 0) then
		local Camera = workspace.CurrentCamera
		Viewport = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720);
	end

	local Width = Clamp(Viewport.X - 20, 520, 800);
	local Height = Clamp(Viewport.Y - 190, 220, 600);
	local HubTop = Clamp((Viewport.Y - (Height + 130)) / 2, 10, 80);

	Hub.HubBar.Size = UDim2.new(0, Width, 0, 60);
	Hub.HubBar.Position = UDim2.new(0.5, -Width / 2, 0, HubTop);
	Hub.PageClipper.Size = UDim2.new(0, Width, 0, Height);
	Hub.PageClipper.Position = UDim2.new(0.5, -Width / 2, 0, HubTop + 60);
	Hub.BottomButtonFrame.Size = UDim2.new(0, Width, 0, 60);
	Hub.BottomButtonFrame.Position = UDim2.new(0.5, -Width / 2, 0, HubTop + Height + 70);
end

ResizeHub();
Connect(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), ResizeHub);
Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), ResizeHub);
if (workspace.CurrentCamera) then
	Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), ResizeHub);
end

local SwitchToPage
local SetVisibility

local MakeTab = function(Page, Title, Icon, Width)
	local Tab = Create("TextButton", {
		Name = Page.Name .. "Tab",
		Parent = Hub.HubBar,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(0, Width or 160, 1, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	local IconLabel = Create("ImageLabel", {
		Name = "Icon",
		Parent = Tab,
		BackgroundTransparency = 1,
		Image = Icon,
		ImageTransparency = 0.5,
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(0, 12, 0.5, -22),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("TextLabel", {
		Name = "Title",
		Parent = IconLabel,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansBold,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.5,
		Text = Title,
		Size = UDim2.new(2.2, 0, 1, 0),
		Position = UDim2.new(1.1, 0, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	local Selection = Create("ImageLabel", {
		Name = "TabSelection",
		Parent = Tab,
		Image = TAB_SELECTION_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(3, 1, 4, 5),
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -6),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Page.Tab = Tab
	Page.Icon = IconLabel
	Page.Selection = Selection

	Connect(Tab.MouseButton1Click, function()
		SwitchToPage(Page);
	end)
end

local LayoutTabs = function()
	local Count = 0

	for _, Page in next, Hub.Pages do
		if (Page.Tab) then
			Count += 1
		end
	end

	local Index = 0
	for _, Page in next, Hub.Pages do
		if (Page.Tab) then
			Index += 1
			local Pos = ((Index - 0.5) / Count);
			Page.Tab.Position = UDim2.new(Pos, -Page.Tab.Size.X.Offset / 2, 0, 0);
		end
	end
end

local GetSelectedPage = function()
	return Hub.CurrentPage
end

local GetPageIndex = function(Page)
	for Index, Other in next, Hub.Pages do
		if (Other == Page) then
			return Index
		end
	end

	return 1
end

SwitchToPage = function(Page, NoStack)
	if (not Page) then
		return
	end

	local OldPage = Hub.CurrentPage
	local OldFrame = OldPage and OldPage.Frame
	local Direction = (GetPageIndex(Page) >= GetPageIndex(OldPage) and 1) or -1

	for _, Other in next, Hub.Pages do
		if (Other.Frame and Other ~= Page and Other ~= OldPage) then
			Other.Frame.Visible = false
		end

		if (Other.Selection) then
			local Title = Other.Icon and Other.Icon:FindFirstChild("Title");

			Other.Selection.Visible = false
			Other.Icon.ImageTransparency = 0.5

			if (Title) then
				Title.TextTransparency = 0.5
			end
		end
	end

	Page.Frame.Parent = Hub.PageView
	Page.Frame.Visible = true

	if (OldFrame and OldFrame ~= Page.Frame and OldFrame.Parent == Hub.PageView and OldFrame.Visible) then
		local PageWidth = math.max(Hub.PageClipper.AbsoluteSize.X, 800);
		Page.Frame.Position = UDim2.new(0, Direction * PageWidth, 0, 0);
		MoveTo(Page.Frame, UDim2.new(0, 0, 0, 0), nil, 12);
		MoveTo(OldFrame, UDim2.new(0, -Direction * PageWidth, 0, 0), nil, 12);
		task.delay(0.22, function()
			if (Hub.CurrentPage ~= OldPage and OldFrame) then
				OldFrame.Visible = false
			end
		end)
	else
		Page.Frame.Position = UDim2.new(0, 0, 0, 0);
	end

	Hub.PageView.CanvasPosition = Vector2.new(0, 0);
	Hub.PageView.CanvasSize = UDim2.new(0, 0, 0, math.max(Page.Frame.Size.Y.Offset, Hub.PageClipper.AbsoluteSize.Y));
	Hub.CurrentPage = Page

	if (Page.Selection) then
		local Title = Page.Icon and Page.Icon:FindFirstChild("Title");

		Page.Selection.Visible = true
		Page.Icon.ImageTransparency = 0

		if (Title) then
			Title.TextTransparency = 0
		end
	end

	if (not NoStack and Hub.MenuStack[#Hub.MenuStack] ~= Page) then
		Insert(Hub.MenuStack, Page);
	end
end

local AddPage = function(Page, Title, Icon, Width)
	Insert(Hub.Pages, Page);

	if (Title) then
		MakeTab(Page, Title, Icon, Width);
	end

	LayoutTabs();
end

local MakeRow = function(Page, Name)
	local Row = Create("ImageButton", {
		Name = Name .. "Frame",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 50),
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	Create("TextLabel", {
		Name = Name .. "Label",
		Parent = Row,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansBold,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Name,
		Size = UDim2.new(0, 230, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Page:AddRow(Row);
	return Row
end

local MakePlayerRow = function(Page, Player, Index)
	local Row = Create("ImageLabel", {
		Name = "PlayerLabel" .. Player.Name,
		Parent = Page.Frame,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/dialog_white.png",
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 10, 10),
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 0, PLAYER_LIST_OFFSET + ((Index - 1) * 80)),
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	Connect(Row.MouseEnter, function()
		Row.ImageTransparency = 0.65
	end)

	Connect(Row.MouseLeave, function()
		Row.ImageTransparency = 0.85
	end)

	Create("TextLabel", {
		Parent = Row,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Player.Name,
		Size = UDim2.new(0, 260, 1, 0),
		Position = UDim2.new(0, 60, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Parent = Row,
		BackgroundTransparency = 1,
		Image = "http://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&userId=" .. tostring(math.max(1, Player.UserId)),
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 12, 0.5, -18),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	local FlagButton = MakeStyledButton(Player.Name .. "FlagButton", "", UDim2.new(0, 44, 0, 40), function()
		if (getgenv().Settings2016 and getgenv().Settings2016.ReportPlayer) then
			getgenv().Settings2016:ReportPlayer(Player);
		end
	end)
	FlagButton.Parent = Row
	FlagButton.Position = UDim2.new(1, -450, 0.5, -20);

	Create("ImageLabel", {
		Parent = FlagButton,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Settings/MenuBarIcons/ReportAbuseTab.png",
		Size = UDim2.new(0, 26, 0, 32),
		Position = UDim2.new(0.5, -13, 0.5, -16),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local ViewButton = MakeStyledButton(Player.Name .. "ViewButton", "View", UDim2.new(0, 104, 0, 40), function()
		pcall(function()
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid");
			local Camera = workspace.CurrentCamera

			if (Humanoid and Camera) then
				Camera.CameraSubject = Humanoid
			end
		end)
	end)
	ViewButton.Parent = Row
	ViewButton.Position = UDim2.new(1, -390, 0.5, -20);

	local FollowButton, FollowLabel
	FollowButton, FollowLabel = MakeStyledButton(Player.Name .. "FollowButton", "Follow", UDim2.new(0, 104, 0, 40), function()
		pcall(function()
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid");
			local Camera = workspace.CurrentCamera

			if (Humanoid and Camera) then
				Camera.CameraSubject = Humanoid
				FollowLabel.Text = "Following"
			end
		end)
	end)
	FollowButton.Parent = Row
	FollowButton.Position = UDim2.new(1, -270, 0.5, -20);

	local FriendText = "Add Friend"
	Protect(function()
		local Status = LocalPlayer:GetFriendStatus(Player);

		if (Status == Enum.FriendStatus.Friend) then
			FriendText = "Friend"
		elseif (Status == Enum.FriendStatus.FriendRequestSent) then
			FriendText = "Request Sent"
		end
	end)

	local FriendButton, FriendLabel
	FriendButton, FriendLabel = MakeStyledButton(Player.Name .. "FriendButton", FriendText, UDim2.new(0, 156, 0, 40), function()
		if (FriendLabel and FriendLabel.Text == "Add Friend") then
			LocalPlayer:RequestFriendship(Player);
			FriendLabel.Text = "Request Sent"
		end
	end)
	FriendButton.Parent = Row
	FriendButton.Position = UDim2.new(1, -164, 0.5, -20);

	return Row
end

local MakeSelector = function(Page, Name, Values, Index, Changed)
	local CurrentIndex = Index or 1
	local Row = MakeRow(Page, Name);
	local SelectorFrame = Create("ImageButton", {
		Name = Name .. "Selector",
		Parent = Row,
		BackgroundTransparency = 1,
		Image = "",
		AutoButtonColor = false,
		Size = UDim2.new(0, 502, 0, 50),
		Position = UDim2.new(0, 320, 0.5, -25),
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	local Left = Create("ImageButton", {
		Parent = SelectorFrame,
		Name = "LeftButton",
		BackgroundTransparency = 1,
		Image = "",
		Size = UDim2.new(0, 60, 0, 50),
		Position = UDim2.new(0, -10, 0.5, -25),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Parent = Left,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Settings/Slider/Left.png",
		Size = UDim2.new(0, 18, 0, 30),
		Position = UDim2.new(1, -24, 0.5, -15),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Right = Create("ImageButton", {
		Parent = SelectorFrame,
		Name = "RightButton",
		BackgroundTransparency = 1,
		Image = "",
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(1, -50, 0.5, -25),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Parent = Right,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Settings/Slider/Right.png",
		Size = UDim2.new(0, 18, 0, 30),
		Position = UDim2.new(0, 6, 0.5, -15),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Label = Create("TextLabel", {
		Parent = SelectorFrame,
		Name = "Selection",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 60, 0, 0),
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 0.2,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.SourceSans,
		TextSize = 24,
		Text = Values[CurrentIndex],
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	local SetText = function(Text, Direction)
		Label.Text = Text
		Label.Position = UDim2.new(0, 60 + ((Direction or 0) * 16), 0, 0);
		Label.TextTransparency = 0.75
		MoveTo(Label, UDim2.new(0, 60, 0, 0));
		FadeText(Label, 0.2);
	end

	local Apply = function(Delta)
		CurrentIndex = CurrentIndex + Delta

		if (CurrentIndex > #Values) then
			CurrentIndex = 1
		elseif (CurrentIndex < 1) then
			CurrentIndex = #Values
		end

		SetText(Values[CurrentIndex], Delta);

		if (Changed) then
			Changed(CurrentIndex, Values[CurrentIndex]);
		end
	end

	Connect(Left.MouseButton1Click, function()
		Apply(-1);
	end)

	Connect(Right.MouseButton1Click, function()
		Apply(1);
	end)

	Connect(SelectorFrame.MouseButton1Click, function()
		Apply(1);
	end)

	return ({
		SetSelectionIndex = function(_, NewIndex)
			CurrentIndex = Clamp(NewIndex, 1, #Values);
			SetText(Values[CurrentIndex], 0);
		end,
		GetSelectedIndex = function()
			return CurrentIndex
		end,
	})
end

local MakeSlider = function(Page, Name, Steps, Index, Changed, MinStep)
	MinStep = MinStep or 0
	local CurrentIndex = Clamp(Index or 1, MinStep, Steps);
	local Row = MakeRow(Page, Name);
	local Holder = Create("Frame", {
		Parent = Row,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 502, 0, 50),
		Position = UDim2.new(0, 320, 0.5, -25),
		Active = true,
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	local Left = Create("ImageButton", {
		Parent = Holder,
		BackgroundTransparency = 1,
		Image = "",
		Size = UDim2.new(0, 60, 0, 50),
		Position = UDim2.new(0, -10, 0.5, -25),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Parent = Left,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Settings/Slider/Left.png",
		Size = UDim2.new(0, 18, 0, 30),
		Position = UDim2.new(1, -24, 0.5, -15),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Right = Create("ImageButton", {
		Parent = Holder,
		BackgroundTransparency = 1,
		Image = "",
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(1, -50, 0.5, -25),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Parent = Right,
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Settings/Slider/Right.png",
		Size = UDim2.new(0, 18, 0, 30),
		Position = UDim2.new(0, 6, 0.5, -15),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Segments = ({})
	local Dragging = false

	local Refresh = function(Immediate)
		for Index2, Segment in next, Segments do
			local Color = (Index2 <= CurrentIndex and Color3.fromRGB(0, 162, 255)) or Color3.fromRGB(78, 84, 96);

			if (Immediate) then
				Segment.BackgroundColor3 = Color
			else
				ColorTo(Segment, Color);
			end
		end
	end

	local SetSliderValue = function(NewIndex)
		NewIndex = Clamp(NewIndex, MinStep, Steps);

		if (CurrentIndex == NewIndex) then
			return
		end

		CurrentIndex = NewIndex
		Refresh();

		if (Changed) then
			Changed(CurrentIndex);
		end
	end

	local SetSliderFromX = function(X)
		local FirstSegment = Segments[1]
		local LastSegment = Segments[Steps]

		if (not FirstSegment or not LastSegment) then
			return
		end

		local StartX = FirstSegment.AbsolutePosition.X
		local EndX = LastSegment.AbsolutePosition.X + LastSegment.AbsoluteSize.X
		local Alpha = Clamp((X - StartX) / (EndX - StartX), 0, 1);

		if (MinStep > 0) then
			SetSliderValue(Clamp(Floor((Alpha * Steps) + 1), MinStep, Steps));
		else
			SetSliderValue(Clamp(Floor(Alpha * (Steps + 1)), 0, Steps));
		end
	end

	for Index2 = 1, Steps do
		local Segment = Create("TextButton", {
			Parent = Holder,
			BackgroundColor3 = Color3.fromRGB(78, 84, 96),
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(0, 35, 0, 25),
			Position = UDim2.new(0, 60 + ((Index2 - 1) * 39), 0.5, -12),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
		})

		Segments[Index2] = Segment
		Connect(Segment.MouseButton1Click, function()
			SetSliderValue(Index2);
		end)
	end

	local Capture = Create("TextButton", {
		Parent = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Size = UDim2.new(0, 400, 1, 0),
		Position = UDim2.new(0, 52, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 5,
	})

	Connect(Capture.InputBegan, function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
			Dragging = true
			SetSliderFromX(Input.Position.X);
		end
	end)

	Connect(Capture.InputChanged, function(Input)
		if (Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)) then
			SetSliderFromX(Input.Position.X);
		end
	end)

	Connect(UserInputService.InputChanged, function(Input)
		if (Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)) then
			SetSliderFromX(Input.Position.X);
		end
	end)

	Connect(UserInputService.InputEnded, function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
			Dragging = false
		end
	end)

	Connect(Left.MouseButton1Click, function()
		SetSliderValue(CurrentIndex - 1);
	end)

	Connect(Right.MouseButton1Click, function()
		SetSliderValue(CurrentIndex + 1);
	end)

	Refresh(true);
	return ({
		SetValue = function(_, NewValue)
			CurrentIndex = Clamp(NewValue, MinStep, Steps);
			Refresh(true);
		end,
		GetValue = function()
			return CurrentIndex
		end,
	})
end

local MakeDropDown = function(Page, Name, Values, Index, Changed)
	local CurrentIndex = Index or 1
	local Row = MakeRow(Page, Name);
	local Button = MakeStyledButton(Name .. "DropDown", Values[CurrentIndex] or "Choose One", UDim2.new(0, 300, 0, 44));
	Button.Parent = Row
	Button.Position = UDim2.new(0, ROW_CONTROL_X, 0.5, -22);

	Create("ImageLabel", {
		Parent = Button,
		BackgroundTransparency = 1,
		Image = DROP_DOWN_IMAGE,
		Size = UDim2.new(0, 15, 0, 10),
		Position = UDim2.new(1, -40, 0.5, -7),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Label = Button:FindFirstChild(Name .. "DropDownTextLabel");
	local Overlay = Create("TextButton", {
		Parent = ScreenGui,
		Name = Name .. "DropDownFullscreenFrame",
		Visible = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 20,
	})

	local Panel = Create("ImageLabel", {
		Parent = Overlay,
		Image = BUTTON_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 6, 46, 44),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 400, 0, math.min(#Values * 51 + 20, 420)),
		Position = UDim2.new(0.5, -200, 0.5, -210),
		ZIndex = SETTINGS_BASE_ZINDEX + 21,
	})

	local List = Create("ScrollingFrame", {
		Parent = Panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		CanvasSize = UDim2.new(0, 0, 0, #Values * 51),
		ScrollBarThickness = 6,
		ZIndex = SETTINGS_BASE_ZINDEX + 21,
	})

	local Rebuild = function(NewValues)
		Values = NewValues or Values

		for _, Child in next, List:GetChildren() do
			if (Child:IsA("TextButton")) then
				Child:Destroy();
			end
		end

		for Index2, Value in next, Values do
			local Option = Create("TextButton", {
				Parent = List,
				Name = "Selection" .. tostring(Index2),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, -28, 0, 50),
				Position = UDim2.new(0, 14, 0, (Index2 - 1) * 51),
				TextColor3 = (Index2 == CurrentIndex and Color3.new(1, 1, 1)) or Color3.new(0.7, 0.7, 0.7),
				Font = Enum.Font.SourceSans,
				TextSize = 24,
				Text = Value,
				ZIndex = SETTINGS_BASE_ZINDEX + 22,
			})

			Connect(Option.MouseButton1Click, function()
				CurrentIndex = Index2
				Label.Text = Value
				Overlay.Visible = false

				if (Changed) then
					Changed(CurrentIndex, Value);
				end
			end)
		end

		List.CanvasSize = UDim2.new(0, 0, 0, #Values * 51);
	end

	Connect(Button.MouseButton1Click, function()
		Overlay.Visible = true
	end)

	Connect(Overlay.MouseButton1Click, function()
		Overlay.Visible = false
	end)

	Rebuild(Values);

	return ({
		UpdateDropDownList = function(_, NewValues)
			Rebuild(NewValues);
		end,
		SetSelectionByValue = function(_, Value)
			for Index2, Item in next, Values do
				if (Item == Value) then
					CurrentIndex = Index2
					Label.Text = Item
					return true
				end
			end

			return false
		end,
		ResetSelectionIndex = function()
			CurrentIndex = 0
			Label.Text = "Choose One"
		end,
	})
end

local PlayersPage = MakePage("Players");
AddPage(PlayersPage, "Players", "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png", 160);

local RebuildPlayersPage = function()
	for _, Child in next, PlayersPage.Frame:GetChildren() do
		if (Child.Name:sub(1, 11) == "PlayerLabel") then
			Child:Destroy();
		end
	end

	local SortedPlayers = Players:GetPlayers();
	table.sort(SortedPlayers, function(PlayerA, PlayerB)
		return PlayerA.Name:upper() < PlayerB.Name:upper()
	end)

	local Count = 0
	for _, Player in next, SortedPlayers do
		if (Player ~= LocalPlayer) then
			Count += 1
			MakePlayerRow(PlayersPage, Player, Count);
		end
	end

	PlayersPage.Frame.Size = UDim2.new(1, 0, 0, PLAYER_LIST_OFFSET + (Count * 80));
end

RebuildPlayersPage();

Connect(Players.PlayerAdded, function(Player)
	RebuildPlayersPage();
end)

Connect(Players.PlayerRemoving, function(Player)
	task.defer(RebuildPlayersPage);
end)

local GamePage = MakePage("GameSettings");
AddPage(GamePage, "Settings", "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png", 170);

MakeSelector(GamePage, "Shift Lock Switch", ({ "On", "Off" }), (GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and 1) or 2, function(Index)
	Protect(function()
		GameSettings.ControlMode = (Index == 1 and Enum.ControlMode.MouseLockSwitch) or Enum.ControlMode.Classic;
	end)
end)

local CameraItems = Enum.ComputerCameraMovementMode:GetEnumItems();
local CameraNames, CameraMap, CameraStart = ({}), ({}), 1
for Index, Item in next, CameraItems do
	local Name = (Item.Name == "Default" and "Default (Classic)") or Item.Name;
	CameraNames[Index] = Name
	CameraMap[Name] = Item

	if (GameSettings.ComputerCameraMovementMode == Item) then
		CameraStart = Index
	end
end

MakeSelector(GamePage, "Camera Mode", CameraNames, CameraStart, function(_, Value)
	Protect(function()
		GameSettings.ComputerCameraMovementMode = CameraMap[Value];
	end)
end)

local MoveItems = Enum.ComputerMovementMode:GetEnumItems();
local MoveNames, MoveMap, MoveStart = ({}), ({}), 1
for Index, Item in next, MoveItems do
	local Name = Item.Name
	if (Name == "Default") then
		Name = "Default (Keyboard)";
	elseif (Name == "KeyboardMouse") then
		Name = "Keyboard + Mouse";
	elseif (Name == "ClickToMove") then
		Name = "Click to Move";
	end

	MoveNames[Index] = Name
	MoveMap[Name] = Item

	if (GameSettings.ComputerMovementMode == Item) then
		MoveStart = Index
	end
end

MakeSelector(GamePage, "Movement Mode", MoveNames, MoveStart, function(_, Value)
	Protect(function()
		GameSettings.ComputerMovementMode = MoveMap[Value];
	end)
end)

local MouseStart = Clamp(Floor((2 / 3) * (math.sqrt((75 * (GameSettings.MouseSensitivity or 1)) - 11) - 2)), 1, 10);
MakeSlider(GamePage, "Mouse Sensitivity", 10, MouseStart, function(Value)
	Value = Clamp(Value, 1, 10);
	SetMouseSensitivity((0.03 * (Value ^ 2)) + (0.08 * Value) + 0.2);
end, 1)

MakeSlider(GamePage, "Volume", 10, Floor((GameSettings.MasterVolume or 1) * 10), function(Value)
	SetMasterVolume(Value / 10);
end)

MakeSelector(GamePage, "Fullscreen", ({ "On", "Off" }), (GameSettings:InFullScreen() and 1) or 2, function()
	Protect(function()
		if (keypress and keyrelease) then
			keypress(0x7A); keyrelease(0x7A);
		end
	end)
end)

local QualityLevels = ({
	Enum.QualityLevel.Level01,
	Enum.QualityLevel.Level04,
	Enum.QualityLevel.Level06,
	Enum.QualityLevel.Level08,
	Enum.QualityLevel.Level10,
	Enum.QualityLevel.Level12,
	Enum.QualityLevel.Level14,
	Enum.QualityLevel.Level16,
	Enum.QualityLevel.Level18,
	Enum.QualityLevel.Level21,
})

local SavedQualityLevels = ({
	Enum.SavedQualitySetting.QualityLevel1,
	Enum.SavedQualitySetting.QualityLevel2,
	Enum.SavedQualitySetting.QualityLevel3,
	Enum.SavedQualitySetting.QualityLevel4,
	Enum.SavedQualitySetting.QualityLevel5,
	Enum.SavedQualitySetting.QualityLevel6,
	Enum.SavedQualitySetting.QualityLevel7,
	Enum.SavedQualitySetting.QualityLevel8,
	Enum.SavedQualitySetting.QualityLevel9,
	Enum.SavedQualitySetting.QualityLevel10,
})

local GetGraphicsSliderStart = function()
	if (GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic or RenderingSettings.QualityLevel == Enum.QualityLevel.Automatic) then
		return 5
	end

	for Index, Quality in next, QualityLevels do
		if (RenderingSettings.QualityLevel == Quality) then
			return Index
		end
	end

	local Saved = tostring(GameSettings.SavedQualityLevel);
	local SavedIndex = tonumber(Saved:match("QualityLevel(%d+)$"));
	return Clamp(SavedIndex or 5, 1, 10)
end

local GraphicsMode = MakeSelector(GamePage, "Graphics Mode", ({ "Automatic", "Manual" }), 1, function(Index)
	Protect(function()
		if (Index == 1) then
			GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic;
			RenderingSettings.QualityLevel = Enum.QualityLevel.Automatic;
		else
			local Value = GetGraphicsSliderStart();
			GameSettings.SavedQualityLevel = SavedQualityLevels[Value];
			RenderingSettings.QualityLevel = QualityLevels[Value];
		end
	end)
end)

if (GameSettings.SavedQualityLevel ~= Enum.SavedQualitySetting.Automatic and RenderingSettings.QualityLevel ~= Enum.QualityLevel.Automatic) then
	GraphicsMode:SetSelectionIndex(2);
end

MakeSlider(GamePage, "Graphics Quality", 10, GetGraphicsSliderStart(), function(Value)
	Value = Clamp(Value, 1, 10);
	Protect(function()
		GraphicsMode:SetSelectionIndex(2);
		GameSettings.SavedQualityLevel = SavedQualityLevels[Value];
		RenderingSettings.QualityLevel = QualityLevels[Value];
	end)
end, 1)

local ReportPage = MakePage("ReportAbuse");
AddPage(ReportPage, "Report", "rbxasset://textures/ui/Settings/MenuBarIcons/ReportAbuseTab.png", 150);

local ReportMode = MakeSelector(ReportPage, "Game or Player?", ({ "Game", "Player" }), 1);
local PlayerNames = ({ "Choose One" })
for _, Player in next, Players:GetPlayers() do
	Insert(PlayerNames, Player.Name);
end

local WhichPlayer = MakeDropDown(ReportPage, "Which Player?", PlayerNames, 1);
Connect(Players.PlayerAdded, function(Player)
	Insert(PlayerNames, Player.Name);
	WhichPlayer:UpdateDropDownList(PlayerNames);
end)

Connect(Players.PlayerRemoving, function(Player)
	for Index, Name in next, PlayerNames do
		if (Name == Player.Name) then
			Remove(PlayerNames, Index);
			break
		end
	end

	WhichPlayer:UpdateDropDownList(PlayerNames);
end)

MakeDropDown(ReportPage, "Type Of Abuse", ({
	"Swearing",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Questions",
	"Offsite Links",
	"Bad Username",
}), 1);

local DescriptionRow = MakeRow(ReportPage, "");
local Description = Create("TextBox", {
	Parent = DescriptionRow,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	Font = Enum.Font.SourceSans,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(49, 49, 49),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Text = "Short Description (Optional)",
	Size = UDim2.new(1, -20, 0, 100),
	Position = UDim2.new(0, 10, 0, 0),
	ZIndex = SETTINGS_BASE_ZINDEX + 3,
})
DescriptionRow.Size = UDim2.new(1, 0, 0, 110);
ReportPage.Frame.Size = UDim2.new(1, 0, 0, ReportPage.Frame.Size.Y.Offset + 60);

local Submit = MakeStyledButton("SubmitButton", "Submit", UDim2.new(0, 198, 0, 50), function()
	warn("[Settings2016] Report submitted locally. Roblox report backend is CoreScript-only in executor context.");
	SetVisibility(false, true);
end)
Submit.Parent = ReportPage.Frame
Submit.Position = UDim2.new(0.5, -99, 0, ReportPage.Frame.Size.Y.Offset + 10);
ReportPage.Frame.Size = UDim2.new(1, 0, 0, ReportPage.Frame.Size.Y.Offset + 70);

local HelpPage = MakePage("Help");
AddPage(HelpPage, "Help", "rbxasset://textures/ui/Settings/MenuBarIcons/HelpTab.png", 130);

local CreateHelpGroup = function(Title, Bindings, Position)
	local Group = Create("Frame", {
		Parent = HelpPage.Frame,
		Name = "PCGroupFrame" .. Title,
		BackgroundTransparency = 1,
		Position = Position,
		Size = UDim2.new(1 / 3, -4, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 2,
	})

	Create("TextLabel", {
		Parent = Group,
		BackgroundTransparency = 1,
		Text = Title,
		Font = Enum.Font.SourceSansBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -9, 0, 30),
		Position = UDim2.new(0, 9, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	for Index, Binding in ipairs(Bindings) do
		local Row = Create("Frame", {
			Parent = Group,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 42),
			Position = UDim2.new(0, 0, 0, 30 + ((Index - 1) * 44)),
			ZIndex = SETTINGS_BASE_ZINDEX + 2,
		})

		Create("TextLabel", {
			Parent = Row,
			BackgroundTransparency = 1,
			Text = Binding[1],
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.45, -9, 1, 0),
			Position = UDim2.new(0, 9, 0, 0),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
		})

		Create("TextLabel", {
			Parent = Row,
			BackgroundTransparency = 1,
			Text = Binding[2],
			Font = Enum.Font.SourceSans,
			TextSize = 18,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.55, 0, 1, 0),
			Position = UDim2.new(0.5, -4, 0, 0),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
		})
	end

	Group.Size = UDim2.new(Group.Size.X.Scale, Group.Size.X.Offset, 0, 30 + (#Bindings * 44));
	return Group
end

local IsOSX = UserInputService:GetPlatform() == Enum.Platform.OSX
local CharMoveFrame = CreateHelpGroup("Character Movement", ({
	({ "Move Forward", "W/Up Arrow" }),
	({ "Move Backward", "S/Down Arrow" }),
	({ "Move Left", "A/Left Arrow" }),
	({ "Move Right", "D/Right Arrow" }),
	({ "Jump", "Space" }),
}), UDim2.new(0, 0, 0, 0));

CreateHelpGroup("Accessories", ({
	({ "Equip Tools", "1,2,3..." }),
	({ "Unequip Tools", "1,2,3..." }),
	({ "Drop Tool", "Backspace" }),
	({ "Use Tool", "Left Mouse Button" }),
	({ "Drop Hats", "+" }),
}), UDim2.new(1 / 3, 4, 0, 0));

CreateHelpGroup("Misc", ({
	({ "Screenshot", "Print Screen" }),
	({ "Record Video", IsOSX and "F12/fn + F12" or "F12" }),
	({ "Dev Console", IsOSX and "F9/fn + F9" or "F9" }),
	({ "Mouselock", "Shift" }),
	({ "Graphics Level", IsOSX and "F10/fn + F10" or "F10" }),
	({ "Fullscreen", IsOSX and "F11/fn + F11" or "F11" }),
}), UDim2.new(2 / 3, 8, 0, 0));

CreateHelpGroup("Camera Movement", ({
	({ "Rotate", "Right Mouse Button" }),
	({ "Zoom In/Out", "Mouse Wheel" }),
	({ "Zoom In", "I" }),
	({ "Zoom Out", "O" }),
}), UDim2.new(0, 0, 0, CharMoveFrame.Size.Y.Offset + 50));

local MenuFrame = CreateHelpGroup("Menu Items", ({
	({ "ROBLOX Menu", "ESC" }),
	({ "Backpack", "~" }),
	({ "Playerlist", "TAB" }),
	({ "Chat", "/" }),
}), UDim2.new(1 / 3, 4, 0, CharMoveFrame.Size.Y.Offset + 50));

HelpPage.Frame.Size = UDim2.new(1, 0, 0, MenuFrame.Position.Y.Offset + MenuFrame.Size.Y.Offset);

local ResetPage = MakePage("ResetCharacter");
AddPage(ResetPage);
MakeText(ResetPage.Frame, "Are you sure you want to reset your character?", UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 0, 0)).TextSize = 36

local ResetCharacter = function()
	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid");

	if (Humanoid) then
		Humanoid.Health = 0
	end

	SetVisibility(false, true);
end

local LeaveGame = function()
	game:Shutdown();
end

local ResetButton = MakeStyledButton("ResetCharacter", "Reset", UDim2.new(0, 200, 0, 50), ResetCharacter)
ResetButton.Parent = ResetPage.Frame
ResetButton.Position = UDim2.new(0.5, -220, 0, 170);
local DontResetButton = MakeStyledButton("DontResetCharacter", "Don't Reset", UDim2.new(0, 200, 0, 50), function()
	SwitchToPage(Hub.MenuStack[#Hub.MenuStack - 1] or GamePage, true);
end)
DontResetButton.Parent = ResetPage.Frame
DontResetButton.Position = UDim2.new(0.5, 20, 0, 170);
ResetPage.Frame.Size = UDim2.new(1, 0, 0, 240);

local LeavePage = MakePage("LeaveGame");
AddPage(LeavePage);
MakeText(LeavePage.Frame, "Are you sure you want to leave the game?", UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 0, 0)).TextSize = 36
local LeaveButton = MakeStyledButton("LeaveGame", "Leave", UDim2.new(0, 200, 0, 50), LeaveGame)
LeaveButton.Parent = LeavePage.Frame
LeaveButton.Position = UDim2.new(0.5, -220, 0, 170);
local DontLeaveButton = MakeStyledButton("DontLeaveGame", "Don't Leave", UDim2.new(0, 200, 0, 50), function()
	SwitchToPage(Hub.MenuStack[#Hub.MenuStack - 1] or GamePage, true);
end)
DontLeaveButton.Parent = LeavePage.Frame
DontLeaveButton.Position = UDim2.new(0.5, 20, 0, 170);
LeavePage.Frame.Size = UDim2.new(1, 0, 0, 240);

local PushPage = function(Page)
	Insert(Hub.MenuStack, GetSelectedPage());
	Hub.HubBar.Visible = false
	SwitchToPage(Page, true);
end

local MakeBottomButton = function(Name, Text, Icon, Position, Clicked)
	local Button = MakeStyledButton(Name .. "Button", Text, UDim2.new(0, 260, 0, 70), Clicked);
	Button.Parent = Hub.BottomButtonFrame
	Button.Position = Position

	Create("ImageLabel", {
		Parent = Button,
		BackgroundTransparency = 1,
		Image = Icon,
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 10, 0, 8),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Label = Button:FindFirstChild(Name .. "ButtonTextLabel");
	if (Label) then
		Label.Position = UDim2.new(0, 10, 0, 0);
		Label.Size = UDim2.new(1, 0, 1, -2);
		ButtonHome[Label] = Label.Position
	end

	return Button
end

MakeBottomButton("ResetCharacter", "    Reset Character", "rbxasset://textures/ui/Settings/Help/ResetIcon.png", UDim2.new(0.5, -400, 0.5, -25), function()
	PushPage(ResetPage);
end)

MakeBottomButton("LeaveGame", "Leave Game", "rbxasset://textures/ui/Settings/Help/LeaveIcon.png", UDim2.new(0.5, -130, 0.5, -25), function()
	PushPage(LeavePage);
end)

MakeBottomButton("Resume", "Resume Game", "rbxasset://textures/ui/Settings/Help/EscapeIcon.png", UDim2.new(0.5, 140, 0.5, -25), function()
	SetVisibility(false);
end)

SetVisibility = function(Visible, NoAnimation, CustomPage)
	if (Hub.Visible == Visible and not CustomPage) then
		return
	end

	Hub.Visible = Visible
	Hub.Modal.Visible = Visible

	if (Visible) then
		Hub.Shield.Visible = true
		Hub.HubBar.Visible = true
		Hub.BottomButtonFrame.Visible = true

		if (NoAnimation) then
			Hub.Shield.Position = SETTINGS_ACTIVE_POSITION
		else
			Hub.Shield.Position = SETTINGS_INACTIVE_POSITION
			MoveTo(Hub.Shield, SETTINGS_ACTIVE_POSITION, nil, 28);
		end

		SwitchToPage(CustomPage or PlayersPage, true);
	else
		if (NoAnimation) then
			Hub.Shield.Position = SETTINGS_INACTIVE_POSITION
			Hub.Shield.Visible = false
		else
			MoveTo(Hub.Shield, SETTINGS_INACTIVE_POSITION, function()
				if (not Hub.Visible) then
					Hub.Shield.Visible = false
				end
			end, 22)
		end
	end
end

local ToggleVisibility = function()
	SetVisibility(not Hub.Visible);
end

SwitchToPage(GamePage, true);

local EscapeAction = function(_, State)
	if (State ~= Enum.UserInputState.Begin) then
		return Enum.ContextActionResult.Sink
	end

	if (Hub.Visible and (Hub.CurrentPage == ResetPage or Hub.CurrentPage == LeavePage)) then
		Hub.HubBar.Visible = true
		SwitchToPage(Hub.MenuStack[#Hub.MenuStack] or GamePage, true);
	else
		ToggleVisibility();
	end

	return Enum.ContextActionResult.Sink
end

Protect(function()
	ContextActionService:BindCoreAction("RBXEscapeMainMenu", EscapeAction, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonStart);
end)

Connect(UserInputService.InputBegan, function(Input, Processed)
	if (Processed) then
		return
	end

	if (Input.KeyCode == Enum.KeyCode.Escape) then
		EscapeAction(nil, Enum.UserInputState.Begin);
	elseif (Hub.Visible and Input.KeyCode == Enum.KeyCode.R and Hub.CurrentPage ~= ResetPage and Hub.CurrentPage ~= LeavePage) then
		PushPage(ResetPage);
	elseif (Hub.Visible and Input.KeyCode == Enum.KeyCode.L and Hub.CurrentPage ~= ResetPage and Hub.CurrentPage ~= LeavePage) then
		PushPage(LeavePage);
	elseif (Hub.Visible and (Input.KeyCode == Enum.KeyCode.Return or Input.KeyCode == Enum.KeyCode.KeypadEnter)) then
		if (Hub.CurrentPage == ResetPage) then
			ResetCharacter();
		elseif (Hub.CurrentPage == LeavePage) then
			LeaveGame();
		end
	end
end)

local HookNativeMenu = function()
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui");
	local Shield = RobloxGui and RobloxGui:FindFirstChild("SettingsClippingShield");
	local Native = Shield and Shield:FindFirstChild("SettingsShield");

	if (Native) then
		Connect(Native:GetPropertyChangedSignal("Visible"), function()
			if (Native.Visible) then
				Native.Visible = false
				SetVisibility((Hub.NativeMenuTarget ~= nil and Hub.NativeMenuTarget) or true);
				Hub.NativeMenuTarget = nil
			end
		end)
	end

	local TopBarApp = CoreGui:FindFirstChild("TopBarApp");
	TopBarApp = TopBarApp and TopBarApp:FindFirstChild("TopBarApp");
	local Holder = TopBarApp and TopBarApp:FindFirstChild("MenuIconHolder");
	local Hit = Holder and Holder:FindFirstChild("TriggerPoint") and Holder.TriggerPoint:FindFirstChild("IconHitArea");

	if (Hit and Hit:IsA("GuiButton")) then
		Connect(Hit.MouseButton1Click, function()
			Hub.NativeMenuTarget = not Hub.Visible
			Spawn(function()
				Wait();
				SetVisibility(Hub.NativeMenuTarget);
				Hub.NativeMenuTarget = nil
			end)
		end)
	end
end

Spawn(HookNativeMenu);

local Api = ({})
function Api:SetVisibility(Visible, NoAnimation, CustomPage)
	SetVisibility(Visible, NoAnimation, CustomPage);
end

function Api:ToggleVisibility()
	ToggleVisibility();
end

function Api:GetVisibility()
	return Hub.Visible
end

function Api:ReportPlayer(Player)
	if (Player) then
		WhichPlayer:SetSelectionByValue(Player.Name);
		ReportMode:SetSelectionIndex(2);
		SetVisibility(true, false, ReportPage);
	end
end

Api.Instance = Hub
getgenv().Settings2016 = Api

return Api
