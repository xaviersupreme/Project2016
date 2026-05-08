local CoreGui = game:GetService("CoreGui");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");
local GuiService = game:GetService("GuiService");
local StarterGui = game:GetService("StarterGui");
local SoundService = game:GetService("SoundService");
local Players = game:GetService("Players");
local SocialService = game:GetService("SocialService");

local LocalPlayer = Players.LocalPlayer
local GameSettings = UserSettings().GameSettings
local RenderingSettings = settings().Rendering

local Spawn, Wait = task.spawn, task.wait
local Insert = table.insert
local Clamp, Floor = math.clamp, math.floor

local SETTINGS_SHIELD_COLOR = Color3.new(41/255, 41/255, 41/255);
local SETTINGS_SHIELD_TRANSPARENCY = 0.2
local SETTINGS_BASE_ZINDEX = 200
local SETTINGS_INACTIVE_POSITION = UDim2.new(0, 0, -1, -36);
local SETTINGS_ACTIVE_POSITION = UDim2.new(0, 0, 0, 0);

local BUTTON_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png";
local BUTTON_SELECTED_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png";
local TAB_BAR_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuBackground.png";
local TAB_SELECTION_IMAGE = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuSelection.png";
local DROP_DOWN_IMAGE = "rbxasset://textures/ui/Settings/DropDown/DropDown.png";
local SLIDER_SELECTED_LEFT_IMAGE = "rbxasset://textures/ui/Settings/Slider/SelectedBarLeft.png";
local SLIDER_SELECTED_RIGHT_IMAGE = "rbxasset://textures/ui/Settings/Slider/SelectedBarRight.png";
local SLIDER_LEFT_IMAGE = "rbxasset://textures/ui/Settings/Slider/BarLeft.png";
local SLIDER_RIGHT_IMAGE = "rbxasset://textures/ui/Settings/Slider/BarRight.png";
local PLAYER_LIST_OFFSET = 20
local DESCRIPTION_PLACEHOLDER = "Short Description (Optional)"
local REPORT_DESCRIPTION_FALLBACK = "Report Reason"
local PAGE_TOP_PADDING = 12
local KEY_F12 = 0x7B
local KEY_PRINT_SCREEN = 0x2C

local ABUSE_TYPES_PLAYER = ({
	"Swearing",
	"Inappropriate Username",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Question",
	"Offsite Links",
})

local ABUSE_TYPES_GAME = ({
	"Inappropriate Content",
	"Bad Model or Script",
	"Offsite Link",
})

local GetHeadshot = function(Player)
	return "http://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&userId=" .. tostring(math.max(1, Player.UserId or Player.userId or 1))
end

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
	local Success = pcall(Callback);

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

local TweenTo = function(Object, Position, Direction, Style, Time, Callback)
	MoveTweens[Object] = (MoveTweens[Object] or 0) + 1
	local Id = MoveTweens[Object]

	local Success = Protect(function()
		Object:TweenPosition(Position, Direction, Style, Time, true, function()
			if (MoveTweens[Object] ~= Id) then
				return
			end

			Object.Position = Position

			if (Callback) then
				Callback();
			end
		end)
	end)

	if (not Success) then
		MoveTo(Object, Position, Callback, math.max(1, Floor((Time or 0.1) * 60)));
	end
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

local VolumeChangeSound = Create("Sound", {
	Name = "VolumeChangeSound",
	Parent = SoundService,
	SoundId = "rbxasset://sounds/uuhhh.mp3",
	Volume = 1,
})
Insert(Data.Objects, VolumeChangeSound);

local PlayVolumeChangeSound = function()
	Protect(function()
		VolumeChangeSound:Stop();
		VolumeChangeSound:Play();
	end)
end

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
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = Text,
		TextWrapped = true,
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Connect(Button.MouseEnter, function()
		Button.Image = BUTTON_SELECTED_IMAGE;
	end)

	Connect(Button.MouseLeave, function()
		Button.Image = BUTTON_IMAGE;
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
		NextY = 0,
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
		Row.Position = UDim2.new(0, 0, 0, self.NextY);
		Insert(self.Rows, Row);
		self.NextY = self.NextY + math.max(1, Row.Size.Y.Offset);
		self.Frame.Size = UDim2.new(1, 0, 0, PAGE_TOP_PADDING + self.NextY);
	end

	return Page
end

local Hub = ({
	Visible = false,
	Pages = ({}),
	MenuStack = ({}),
	CurrentPage = nil,
	NativeMenuTarget = nil,
	SuppressNativeOpenUntil = 0,
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
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 1, 0),
	Text = "",
	Active = true,
	AutoButtonColor = false,
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

	local Width = (Viewport.X < 820 and Clamp(Viewport.X - 10, 520, 800)) or 800
	local BarHeight = 60
	local LargestPageSize = 600
	local MinimumPageSize = 150
	local BufferSize = 0.05 * Viewport.Y
	local ExtraSpace = (BufferSize * 2) + (BarHeight * 2)
	local UsableScreenHeight = Viewport.Y - ExtraSpace
	local Height = Clamp(UsableScreenHeight, MinimumPageSize, LargestPageSize)

	Hub.HubBar.Size = UDim2.new(0, Width, 0, BarHeight);
	Hub.HubBar.Position = UDim2.new(0.5, -Width / 2, 0.5, -Height / 2 - BarHeight);
	Hub.PageClipper.Size = UDim2.new(0, Width, 0, Height);
	Hub.PageClipper.Position = UDim2.new(0.5, -Width / 2, 0.5, -Height / 2);
	Hub.BottomButtonFrame.Size = UDim2.new(0, Width, 0, BarHeight);
	Hub.BottomButtonFrame.Position = UDim2.new(0.5, -Width / 2, 0.5, Height / 2);
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
		Size = UDim2.new(1.05, 0, 1, 0),
		Position = UDim2.new(1.2, 0, 0, 0),
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

SwitchToPage = function(Page, NoStack, NoAnimation)
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

	if (OldFrame and OldFrame ~= Page.Frame and OldFrame.Parent == Hub.PageView and OldFrame.Visible and not NoAnimation) then
		local PageWidth = math.max(Hub.PageClipper.AbsoluteSize.X, 800);
		Page.Frame.Position = UDim2.new(0, Direction * PageWidth, 0, PAGE_TOP_PADDING);
		TweenTo(Page.Frame, UDim2.new(0, 0, 0, PAGE_TOP_PADDING), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.1);
		TweenTo(OldFrame, UDim2.new(0, -Direction * PageWidth, 0, PAGE_TOP_PADDING), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1);
		task.delay(0.12, function()
			if (Hub.CurrentPage ~= OldPage and OldFrame) then
				OldFrame.Visible = false
			end
		end)
	else
		Page.Frame.Position = UDim2.new(0, 0, 0, PAGE_TOP_PADDING);
		if (OldFrame and OldFrame ~= Page.Frame) then
			OldFrame.Visible = false
		end
	end

	Hub.PageView.CanvasPosition = Vector2.new(0, 0);
	Hub.PageView.CanvasSize = UDim2.new(0, 0, 0, math.max(Page.Frame.Size.Y.Offset + PAGE_TOP_PADDING, Hub.PageClipper.AbsoluteSize.Y));
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

local MakeRow = function(Page, Name, Height)
	local Row = Create("ImageButton", {
		Name = Name .. "Frame",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		Active = false,
		AutoButtonColor = false,
		Selectable = false,
		Size = UDim2.new(1, 0, 0, Height or 50),
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
		Size = UDim2.new(0, 200, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Page:AddRow(Row);
	return Row
end

local OpenReportPlayer

local RunAfterMenuCloses = function(Callback)
	SetVisibility(false);

	Spawn(function()
		Wait(0.45);

		if (Callback) then
			Callback();
		end
	end)
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
		Name = "NameLabel",
		Parent = Row,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Player.Name,
		Size = UDim2.new(1, -470, 1, 0),
		Position = UDim2.new(0, 60, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	Create("ImageLabel", {
		Name = "Icon",
		Parent = Row,
		BackgroundTransparency = 1,
		Image = GetHeadshot(Player),
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 12, 0.5, -18),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	local CanTargetPlayer = Player ~= LocalPlayer and (Player.UserId or Player.userId or 0) > 1
	local FlagButton, ViewButton = nil, nil

	if (CanTargetPlayer) then
		FlagButton = MakeStyledButton(Player.Name .. "FlagButton", "", UDim2.new(0, 44, 0, 40), function()
			if (OpenReportPlayer) then
				OpenReportPlayer(Player);
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

		ViewButton = MakeStyledButton(Player.Name .. "ViewButton", "View", UDim2.new(0, 104, 0, 40), function()
			local UserId = Player.UserId or Player.userId
			if (not UserId or UserId <= 0) then
				return
			end

			RunAfterMenuCloses(function()
				local Success = Protect(function()
					GuiService:InspectPlayerFromUserId(UserId);
				end)

				if (not Success) then
					Protect(function()
						StarterGui:SetCore("InspectPlayerFromUserId", UserId);
					end)
				end
			end)
		end)
		ViewButton.Parent = Row
		ViewButton.Position = UDim2.new(1, -390, 0.5, -20);
	end

	local Status = nil
	Protect(function()
		if (CanTargetPlayer and (LocalPlayer.UserId or LocalPlayer.userId or 0) > 1) then
			Status = LocalPlayer:GetFriendStatus(Player)
		end
	end)

	local FriendButton, FriendLabel
	if (not Status) then
		FriendButton = Create("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 156, 0, 40),
			Position = UDim2.new(1, -270, 0.5, -20),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
			Parent = Row,
		})
	elseif (Status == Enum.FriendStatus.Friend) then
		FriendButton = Create("TextButton", {
			Text = "Friend",
			BackgroundTransparency = 1,
			Font = Enum.Font.SourceSans,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(0, 156, 0, 40),
			Position = UDim2.new(1, -270, 0.5, -20),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
			Parent = Row,
		})
	elseif (Status == Enum.FriendStatus.FriendRequestSent) then
		FriendButton = Create("TextButton", {
			Text = "Request Sent",
			BackgroundTransparency = 1,
			Font = Enum.Font.SourceSans,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(0, 156, 0, 40),
			Position = UDim2.new(1, -270, 0.5, -20),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
			Parent = Row,
		})
	else
		FriendButton, FriendLabel = MakeStyledButton("FriendStatus", "Add Friend", UDim2.new(0, 156, 0, 40), function()
			if (FriendLabel and FriendLabel.Text ~= "") then
				FriendButton.ImageTransparency = 1
				FriendLabel.Text = ""
				Protect(function()
					LocalPlayer:RequestFriendship(Player)
				end)
			end
		end)
		FriendButton.Parent = Row
		FriendButton.Position = UDim2.new(1, -270, 0.5, -20)
		if (FriendLabel) then
			FriendLabel.ZIndex = SETTINGS_BASE_ZINDEX + 3
			FriendLabel.Position = FriendLabel.Position + UDim2.new(0, 0, 0, 1)
		end
	end

	if (FriendButton) then
		FriendButton.Name = "FriendStatus"
	end

	for _, Button in next, ({ FlagButton, ViewButton, FriendButton }) do
		if (Button) then
			Connect(Button.MouseEnter, function()
				Row.ImageTransparency = 0.65
			end)
			Connect(Button.MouseLeave, function()
				Row.ImageTransparency = 0.85
			end)
		end
	end

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
		Position = UDim2.new(1, -502, 0.5, -25),
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

	local SelectorApi = ({
		CurrentIndex = CurrentIndex,
		SelectorFrame = SelectorFrame,
		Selection = SelectorFrame,
		RowFrame = Row,
		TextLabel = Label,
		Interactable = true,
	})

	local SetText = function(Text, Direction)
		Label.Text = Text
		Label.Position = UDim2.new(0, 60 + ((Direction or 0) * 16), 0, 0);
		Label.TextTransparency = 0.75
		MoveTo(Label, UDim2.new(0, 60, 0, 0));
		FadeText(Label, 0.2);
	end

	local Apply = function(Delta)
		if (not SelectorApi.Interactable) then
			return
		end

		CurrentIndex = CurrentIndex + Delta

		if (CurrentIndex > #Values) then
			CurrentIndex = 1
		elseif (CurrentIndex < 1) then
			CurrentIndex = #Values
		end

		SelectorApi.CurrentIndex = CurrentIndex
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

	function SelectorApi:SetSelectionIndex(NewIndex, FireChanged)
		if (not NewIndex or #Values == 0) then
			return
		end

			CurrentIndex = Clamp(NewIndex, 1, #Values);
			SelectorApi.CurrentIndex = CurrentIndex
			SetText(Values[CurrentIndex], 0);

		if (Changed and FireChanged) then
			Changed(CurrentIndex, Values[CurrentIndex]);
		end
	end

	function SelectorApi:SetPosition(Position)
		SelectorFrame.Position = Position
	end

	function SelectorApi:SetSize(Size)
		SelectorFrame.Size = Size
	end

	function SelectorApi:SetInteractable(Interactable)
		SelectorApi.Interactable = Interactable
		SelectorFrame.ImageTransparency = Interactable and 0 or 0.65
		Label.TextTransparency = Interactable and 0.2 or 0.65
		Left.Visible = Interactable
		Right.Visible = Interactable
	end

	function SelectorApi:GetSelectedIndex()
		return CurrentIndex
	end

	function SelectorApi:GetSelectedValue()
		return Values[CurrentIndex]
	end

	return SelectorApi
end

local MakeSlider = function(Page, Name, Steps, Index, Changed, MinStep)
	MinStep = MinStep or 0
	local CurrentIndex = Clamp(Index or 1, MinStep, Steps);
	local Row = MakeRow(Page, Name);
	local Holder = Create("Frame", {
		Parent = Row,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 502, 0, 50),
		Position = UDim2.new(1, -502, 0.5, -25),
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
	local SliderApi = ({
		SliderFrame = Holder,
		Selection = Holder,
		RowFrame = Row,
		Interactable = true,
	})

	local Refresh = function(Immediate)
		for Index2, Segment in next, Segments do
			local Selected = SliderApi.Interactable and Index2 <= CurrentIndex
			local Color = (Selected and Color3.fromRGB(0, 162, 255)) or Color3.fromRGB(78, 84, 96);

			if (Index2 == 1 or Index2 == Steps) then
				Segment.Image = (Selected and ((Index2 == 1 and SLIDER_SELECTED_LEFT_IMAGE) or SLIDER_SELECTED_RIGHT_IMAGE)) or ((Index2 == 1 and SLIDER_LEFT_IMAGE) or SLIDER_RIGHT_IMAGE)
				Segment.ImageTransparency = 0.36
				Segment.BackgroundTransparency = 1
			else
				if (Immediate) then
					Segment.BackgroundColor3 = Color
				else
					ColorTo(Segment, Color);
				end
			end
		end

		Left.Visible = SliderApi.Interactable and CurrentIndex > MinStep
		Right.Visible = SliderApi.Interactable and CurrentIndex < Steps
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
		if (not SliderApi.Interactable) then
			return
		end

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
		local Segment = Create("ImageButton", {
			Parent = Holder,
			BackgroundColor3 = Color3.fromRGB(78, 84, 96),
			BackgroundTransparency = 0.36,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "",
			ImageTransparency = 0.36,
			Size = UDim2.new(0, 35, 0, 25),
			Position = UDim2.new(0, 60 + ((Index2 - 1) * 39), 0.5, -12),
			ZIndex = SETTINGS_BASE_ZINDEX + 3,
		})

		if (Index2 == 1 or Index2 == Steps) then
			Segment.BackgroundTransparency = 1
			Segment.ScaleType = Enum.ScaleType.Slice
			Segment.SliceCenter = Rect.new(3, 3, 32, 21)
		end

		Segments[Index2] = Segment
		Connect(Segment.MouseButton1Click, function()
			if (SliderApi.Interactable) then
				SetSliderValue(Index2);
			end
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
		if (SliderApi.Interactable) then
			SetSliderValue(CurrentIndex - 1);
		end
	end)

	Connect(Right.MouseButton1Click, function()
		if (SliderApi.Interactable) then
			SetSliderValue(CurrentIndex + 1);
		end
	end)

	Refresh(true);

	function SliderApi:SetValue(NewValue)
		CurrentIndex = Clamp(NewValue, MinStep, Steps);
		Refresh(true);
	end

	function SliderApi:GetValue()
		return CurrentIndex
	end

	function SliderApi:SetInteractable(Interactable)
		SliderApi.Interactable = Interactable
		Holder.Active = Interactable
		Holder.ZIndex = SETTINGS_BASE_ZINDEX + (Interactable and 2 or 1)

		for _, Segment in next, Segments do
			Segment.Active = Interactable
			Segment.Selectable = Interactable
			Segment.ZIndex = SETTINGS_BASE_ZINDEX + (Interactable and 3 or 1)
		end

		Refresh(true);
	end

	function SliderApi:SetZIndex(NewZIndex)
		Holder.ZIndex = NewZIndex
		Left.ZIndex = NewZIndex + 1
		Right.ZIndex = NewZIndex + 1

		for _, Segment in next, Segments do
			Segment.ZIndex = NewZIndex + 1
		end
	end

	function SliderApi:SetMinStep(NewMinStep)
		MinStep = Clamp(NewMinStep or 0, 0, Steps)
		CurrentIndex = Clamp(CurrentIndex, MinStep, Steps)
		Refresh(true);
	end

	return SliderApi
end

local MakeDropDown = function(Page, Name, Values, Index, Changed)
	local CurrentIndex = Index
	local Row = MakeRow(Page, Name);
	local Button = MakeStyledButton(Name .. "DropDown", Values[CurrentIndex] or "Choose One", UDim2.new(0, 300, 0, 44));
	Button.Parent = Row
	Button.Position = UDim2.new(1, -350, 0.5, -22);

	local Arrow = Create("ImageLabel", {
		Parent = Button,
		BackgroundTransparency = 1,
		Image = DROP_DOWN_IMAGE,
		Size = UDim2.new(0, 15, 0, 10),
		Position = UDim2.new(1, -40, 0.5, -7),
		ZIndex = SETTINGS_BASE_ZINDEX + 4,
	})

	local Label = Button:FindFirstChild(Name .. "DropDownTextLabel");
	local DropDownApi = ({
		CurrentIndex = CurrentIndex,
		DropDownFrame = Button,
		Selection = Button,
		Interactable = true,
	})

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
		Size = UDim2.new(0, 400, 0.9, 0),
		Position = UDim2.new(0.5, -200, 0.05, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 21,
	})

	local List = Create("ScrollingFrame", {
		Parent = Panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 1, -25),
		Position = UDim2.new(0, 10, 0, 10),
		CanvasSize = UDim2.new(0, 0, 0, #Values * 51),
		ScrollBarThickness = 6,
		ZIndex = SETTINGS_BASE_ZINDEX + 21,
	})

	local SetSelection = function(NewIndex, FireChanged)
		CurrentIndex = NewIndex
		DropDownApi.CurrentIndex = CurrentIndex

		local Value = CurrentIndex and Values[CurrentIndex] or nil
		Label.Text = Value or "Choose One"

		if (Changed and FireChanged) then
			Changed(CurrentIndex, Value);
		end
	end

	local Rebuild = function(NewValues)
		Values = NewValues or Values

		if (CurrentIndex and CurrentIndex > #Values) then
			CurrentIndex = nil
			DropDownApi.CurrentIndex = nil
		end

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
				SetSelection(Index2, true);
				Overlay.Visible = false
			end)
		end

		List.CanvasSize = UDim2.new(0, 0, 0, #Values * 51);
		SetSelection(CurrentIndex, false);
	end

	Connect(Button.MouseButton1Click, function()
		if (DropDownApi.Interactable) then
			Overlay.Visible = true
		end
	end)

	Connect(Overlay.MouseButton1Click, function()
		Overlay.Visible = false
	end)

	Rebuild(Values);

	function DropDownApi:UpdateDropDownList(NewValues)
		Rebuild(NewValues);
	end

	function DropDownApi:SetSelectionIndex(NewIndex, FireChanged)
		if (not NewIndex or NewIndex < 1 or NewIndex > #Values) then
			SetSelection(nil, FireChanged);
			return false
		end

		SetSelection(NewIndex, FireChanged);
		return true
	end

	function DropDownApi:SetSelectionByValue(Value, FireChanged)
		for Index2, Item in next, Values do
			if (Item == Value) then
				SetSelection(Index2, FireChanged);
				return true
			end
		end

		return false
	end

	function DropDownApi:ResetSelectionIndex(FireChanged)
		SetSelection(nil, FireChanged);
	end

	function DropDownApi:GetSelectedIndex()
		return CurrentIndex
	end

	function DropDownApi:GetSelectedValue()
		return CurrentIndex and Values[CurrentIndex] or nil
	end

	function DropDownApi:SetInteractable(Interactable)
		DropDownApi.Interactable = Interactable
		Button.ImageTransparency = Interactable and 0 or 0.65
		Button.Active = Interactable
		Button.Selectable = Interactable
		if (Label) then
			Label.TextTransparency = Interactable and 0 or 0.65
		end
		if (Arrow) then
			Arrow.ImageTransparency = Interactable and 0 or 0.65
		end
	end

	return DropDownApi
end

local ActiveAlert = nil
local ShowAlert = function(AlertMessage, OkButtonText, Cleanup)
	if (ActiveAlert) then
		ActiveAlert:Destroy();
		ActiveAlert = nil
	end

	Hub.HubBar.Visible = false
	Hub.PageClipper.Visible = false
	Hub.BottomButtonFrame.Visible = false

	local Alert = Create("ImageLabel", {
		Name = "AlertViewBacking",
		Parent = Hub.Shield,
		Image = BUTTON_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 6, 46, 44),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 400, 0, 350),
		Position = UDim2.new(0.5, -200, 0.5, -175),
		ZIndex = SETTINGS_BASE_ZINDEX + 30,
	})
	ActiveAlert = Alert

	Create("TextLabel", {
		Name = "AlertViewText",
		Parent = Alert,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.95, 0, 0.6, 0),
		Position = UDim2.new(0.025, 0, 0.05, 0),
		Font = Enum.Font.SourceSansBold,
		TextSize = 36,
		Text = AlertMessage,
		TextWrapped = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = SETTINGS_BASE_ZINDEX + 31,
	})

	local Button, ButtonText = MakeStyledButton("AlertViewButton", OkButtonText or "Ok", UDim2.new(0, 200, 0, 50), function()
		if (ActiveAlert) then
			ActiveAlert:Destroy();
			ActiveAlert = nil
		end

		if (Cleanup) then
			Cleanup();
		else
			Hub.HubBar.Visible = true
			Hub.PageClipper.Visible = true
			Hub.BottomButtonFrame.Visible = true
		end
	end)
	Button.Parent = Alert
	Button.Position = UDim2.new(0.5, -100, 0.65, 0)
	Button.ZIndex = SETTINGS_BASE_ZINDEX + 31
	ButtonText.ZIndex = SETTINGS_BASE_ZINDEX + 32
end

local PlayersPage = MakePage("Players");
AddPage(PlayersPage, "Players", "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png", 150);

if (PlayersPage.Icon) then
	PlayersPage.Icon.Size = UDim2.new(0, 44, 0, 37)
	PlayersPage.Icon.Position = UDim2.new(0, 15, 0.5, -18)
end

local RebuildPlayersPage = function()
	for _, Child in next, PlayersPage.Frame:GetChildren() do
		if (Child.Name:sub(1, 11) == "PlayerLabel") then
			Child:Destroy();
		end
	end

	local SortedPlayers = Players:GetPlayers();
	table.sort(SortedPlayers, function(PlayerA, PlayerB)
		return PlayerA.Name < PlayerB.Name
	end)

	local Count = 0
	for _, Player in next, SortedPlayers do
		Count += 1
		MakePlayerRow(PlayersPage, Player, Count);
	end

	PlayersPage.Frame.Size = UDim2.new(1, 0, 0, PLAYER_LIST_OFFSET + (Count * 80) - 5);
end

RebuildPlayersPage();

Connect(Players.PlayerAdded, function(Player)
	RebuildPlayersPage();
end)

Connect(Players.PlayerRemoving, function(Player)
	task.defer(RebuildPlayersPage);
end)

Protect(function()
	Connect(LocalPlayer.FriendStatusChanged, function()
		RebuildPlayersPage();
	end)
end)

local GamePage = MakePage("GameSettings");
AddPage(GamePage, "Settings", "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png", 170);

local IsTouchClient = UserInputService.TouchEnabled
local CameraDefaultString = IsTouchClient and "Default (Follow)" or "Default (Classic)"
local MovementDefaultString = IsTouchClient and "Default (Thumbstick)" or "Default (Keyboard)"
local ClickToMoveString = IsTouchClient and "Tap to Move" or "Click to Move"

local GetSetting = function(Object, Property, Default)
	local Success, Value = pcall(function()
		return Object[Property]
	end)

	if (Success and Value ~= nil) then
		return Value
	end

	return Default
end

local SetSetting = function(Object, Property, Value)
	Protect(function()
		Object[Property] = Value
	end)
end

local MakeSectionHeader = function(Page, Title)
	local Row = MakeRow(Page, Title, 64);
	local Label = Row:FindFirstChild(Title .. "Label")
	if (Label) then
		Label.TextSize = 28
		Label.TextColor3 = Color3.fromRGB(190, 210, 255)
		Label.Size = UDim2.new(1, -20, 1, -10)
		Label.Position = UDim2.new(0, 10, 0, 10)
	end
	return Row
end

local MakeValueRow = function(Page, Name, Value)
	local Row = MakeRow(Page, Name);
	local ValueLabel = Create("TextLabel", {
		Name = Name .. "Value",
		Parent = Row,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(Value or "Unavailable"),
		Size = UDim2.new(0, 360, 1, 0),
		Position = UDim2.new(1, -380, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})

	return ValueLabel, Row
end

local MakeButtonRow = function(Page, Name, Text, Clicked)
	local Row = MakeRow(Page, Name);
	local Button = MakeStyledButton(Name .. "Action", Text, UDim2.new(0, 300, 0, 44), Clicked)
	Button.Parent = Row
	Button.Position = UDim2.new(1, -400, 0.5, -22)
	return Button, Row
end

local MakeBooleanSelector = function(Page, Name, Object, Property, OnFirst, OffSecond)
	local Current = GetSetting(Object, Property, false)
	local Start = ((Current == true or Current == 1) and 1) or 2
	return MakeSelector(Page, Name, ({ OnFirst or "On", OffSecond or "Off" }), Start, function(Index)
		SetSetting(Object, Property, Index == 1)
	end)
end

MakeSectionHeader(GamePage, "View & Controls");

local MakeOverrideText = function(Row)
	return Create("TextLabel", {
		Name = "DevOverrideLabel",
		Parent = Row,
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "Set by Developer",
		Visible = false,
		Size = UDim2.new(0, 200, 1, 0),
		Position = UDim2.new(1, -350, 0, 0),
		ZIndex = SETTINGS_BASE_ZINDEX + 3,
	})
end

local SetChangerVisible = function(Changer, OverrideText, Visible)
	if (Changer) then
		Changer:SetInteractable(Visible);
		Changer.SelectorFrame.Visible = Visible
	end

	if (OverrideText) then
		OverrideText.Visible = not Visible
	end
end

local ShiftLockMode, ShiftLockOverride = nil, nil
if (UserInputService.MouseEnabled and UserInputService.KeyboardEnabled) then
	ShiftLockMode = MakeSelector(GamePage, "Shift Lock Switch", ({ "On", "Off" }), (GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and 1) or 2, function(Index)
		Protect(function()
			GameSettings.ControlMode = (Index == 1 and Enum.ControlMode.MouseLockSwitch) or Enum.ControlMode.Classic;
		end)
	end)
	ShiftLockOverride = MakeOverrideText(ShiftLockMode.RowFrame);
end

local CameraItems = (IsTouchClient and Enum.TouchCameraMovementMode or Enum.ComputerCameraMovementMode):GetEnumItems();
local CameraNames, CameraMap, CameraStart = ({}), ({}), 1
for Index, Item in next, CameraItems do
	local Name = (Item.Name == "Default" and CameraDefaultString) or Item.Name;
	CameraNames[Index] = Name
	CameraMap[Name] = Item

	if ((IsTouchClient and GameSettings.TouchCameraMovementMode == Item) or ((not IsTouchClient) and GameSettings.ComputerCameraMovementMode == Item)) then
		CameraStart = Index
	end
end

local CameraMode = MakeSelector(GamePage, "Camera Mode", CameraNames, CameraStart, function(_, Value)
	Protect(function()
		if (IsTouchClient) then
			GameSettings.TouchCameraMovementMode = CameraMap[Value];
		else
			GameSettings.ComputerCameraMovementMode = CameraMap[Value];
		end
	end)
end)
local CameraOverride = MakeOverrideText(CameraMode.RowFrame);

local MoveItems = (IsTouchClient and Enum.TouchMovementMode or Enum.ComputerMovementMode):GetEnumItems();
local MoveNames, MoveMap, MoveStart = ({}), ({}), 1
for Index, Item in next, MoveItems do
	local Name = Item.Name
	if (Name == "Default") then
		Name = MovementDefaultString;
	elseif (Name == "KeyboardMouse") then
		Name = "Keyboard + Mouse";
	elseif (Name == "ClickToMove") then
		Name = ClickToMoveString;
	end

	MoveNames[Index] = Name
	MoveMap[Name] = Item

	if ((IsTouchClient and GameSettings.TouchMovementMode == Item) or ((not IsTouchClient) and GameSettings.ComputerMovementMode == Item)) then
		MoveStart = Index
	end
end

local MovementMode = MakeSelector(GamePage, "Movement Mode", MoveNames, MoveStart, function(_, Value)
	Protect(function()
		if (IsTouchClient) then
			GameSettings.TouchMovementMode = MoveMap[Value];
		else
			GameSettings.ComputerMovementMode = MoveMap[Value];
		end
	end)
end)
local MovementOverride = MakeOverrideText(MovementMode.RowFrame);

local UpdateDevChoiceSettings = function(Property)
	if (ShiftLockMode and (not Property or Property == "DevEnableMouseLock")) then
		local CanUseShiftLock = true
		Protect(function()
			CanUseShiftLock = LocalPlayer.DevEnableMouseLock
		end)
		SetChangerVisible(ShiftLockMode, ShiftLockOverride, CanUseShiftLock);
	end

	if (not Property or Property == "DevComputerCameraMode" or Property == "DevTouchCameraMode") then
		local CanUseCamera = true
		Protect(function()
			CanUseCamera = (IsTouchClient and LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice) or ((not IsTouchClient) and LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice)
		end)
		SetChangerVisible(CameraMode, CameraOverride, CanUseCamera);
	end

	if (not Property or Property == "DevComputerMovementMode" or Property == "DevTouchMovementMode") then
		local CanUseMovement = true
		Protect(function()
			CanUseMovement = (IsTouchClient and LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice) or ((not IsTouchClient) and LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice)
		end)
		SetChangerVisible(MovementMode, MovementOverride, CanUseMovement);
	end
end

UpdateDevChoiceSettings();
Connect(LocalPlayer.Changed, UpdateDevChoiceSettings);

local MouseStart = Clamp(Floor((2 / 3) * (math.sqrt((75 * (GameSettings.MouseSensitivity or 1)) - 11) - 2)), 1, 10);
MakeSlider(GamePage, "Mouse Sensitivity", 10, MouseStart, function(Value)
	Value = Clamp(Value, 1, 10);
	SetMouseSensitivity((0.03 * (Value ^ 2)) + (0.08 * Value) + 0.2);
end, 1)

MakeBooleanSelector(GamePage, "UI Navigation Toggle", GameSettings, "UiNavigationKeyBindEnabled")
MakeBooleanSelector(GamePage, "People's Names", GameSettings, "PlayerNamesEnabled", "Show", "Hide")
MakeBooleanSelector(GamePage, "My Badges", GameSettings, "BadgeVisible", "Show", "Hide")

MakeSectionHeader(GamePage, "Audio");

MakeSlider(GamePage, "Volume", 10, Floor((GameSettings.MasterVolume or 1) * 10), function(Value)
	SetMasterVolume(Value / 10);
	PlayVolumeChangeSound();
end)

MakeSectionHeader(GamePage, "Chat & Language");

MakeButtonRow(GamePage, "Give Translation Feedback", "Give Feedback", function()
	RunAfterMenuCloses(function()
		pcall(function()
			SocialService:PromptFeedbackSubmissionAsync()
		end)
	end)
end)

MakeBooleanSelector(GamePage, "Automatic Chat Translation", GameSettings, "ChatTranslationEnabled")
MakeBooleanSelector(GamePage, "Chat Translation Language", GameSettings, "ChatTranslationToggleEnabled")
MakeBooleanSelector(GamePage, "View Untranslated Messages", GameSettings, "ChatTranslationFTUXShown")

MakeSectionHeader(GamePage, "Display & Graphics");

MakeSelector(GamePage, "Fullscreen", ({ "On", "Off" }), (GameSettings:InFullScreen() and 1) or 2, function()
	Protect(function()
		local Success = pcall(function()
			GuiService:ToggleFullscreen();
		end)

		if ((not Success) and keypress and keyrelease) then
			keypress(0x7A); keyrelease(0x7A);
		end
	end)
end)

MakeBooleanSelector(GamePage, "Performance Stats", GameSettings, "PerformanceStatsVisible")

MakeButtonRow(GamePage, "MicroProfiler", "Open", function()
	RunAfterMenuCloses(function()
		SetSetting(GameSettings, "OnScreenProfilerEnabled", true)
		if (keypress and keyrelease) then
			keypress(0x75); keyrelease(0x75);
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
	if (type(GameSettings.SavedQualityLevel) == "number") then
		if (GameSettings.SavedQualityLevel <= 0) then
			return 5
		end

		return Clamp(GameSettings.SavedQualityLevel, 1, 10)
	end

	if (type(RenderingSettings.QualityLevel) == "number" and RenderingSettings.QualityLevel <= 0) then
		return 5
	end

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

local GraphicsSlider = nil
local GraphicsMode = nil

Protect(function()
	RenderingSettings.EnableFRM = true
end)

local GetEnumItemByValue = function(EnumType, Value)
	local Items = {}
	Protect(function()
		Items = EnumType:GetEnumItems()
	end)

	for _, Item in next, Items do
		if (Item.Value == Value) then
			return Item
		end
	end

	return nil
end

local SetGraphicsQuality = function(NewValue, AutomaticSettingAllowed)
	NewValue = tonumber(NewValue) or 0

	local MaxQualityLevel = 21
	Protect(function()
		MaxQualityLevel = RenderingSettings:GetMaxQualityLevel()
	end)

	local NewQualityLevel = 0
	if (NewValue > 0 or not AutomaticSettingAllowed) then
		local Percentage = NewValue / 10
		NewQualityLevel = Floor((MaxQualityLevel - 1) * Percentage)

		if (NewQualityLevel == 20) then
			NewQualityLevel = 21
		elseif (NewValue == 1) then
			NewQualityLevel = 1
		elseif (NewValue < 1 and not AutomaticSettingAllowed) then
			NewValue = 1
			NewQualityLevel = 1
		elseif (NewQualityLevel > MaxQualityLevel) then
			NewQualityLevel = MaxQualityLevel - 1
		end
	end

	local SavedQuality = (NewValue <= 0 and AutomaticSettingAllowed and Enum.SavedQualitySetting.Automatic) or GetEnumItemByValue(Enum.SavedQualitySetting, NewValue) or SavedQualityLevels[NewValue]
	local RenderQuality = (NewValue <= 0 and AutomaticSettingAllowed and Enum.QualityLevel.Automatic) or GetEnumItemByValue(Enum.QualityLevel, NewQualityLevel) or QualityLevels[NewValue]

	Protect(function()
		RenderingSettings.EnableFRM = true
	end)
	Protect(function()
		GameSettings.SavedQualityLevel = NewValue
	end)
	Protect(function()
		GameSettings.SavedQualityLevel = SavedQuality;
	end)
	Protect(function()
		RenderingSettings.QualityLevel = NewQualityLevel
	end)
	Protect(function()
		RenderingSettings.QualityLevel = RenderQuality;
	end)
	Protect(function()
		RenderingSettings.EditQualityLevel = NewQualityLevel
	end)
	Protect(function()
		RenderingSettings.EditQualityLevel = RenderQuality;
	end)
	Protect(function()
		RenderingSettings.AutoFRMLevel = NewQualityLevel
	end)
end

local SetGraphicsToAuto = function()
	if (GraphicsSlider) then
		GraphicsSlider:SetInteractable(false);
	end

	SetGraphicsQuality(0, true);
end

local SetGraphicsToManual = function(Value)
	Value = Clamp(Value or GetGraphicsSliderStart(), 1, 10);

	if (GraphicsSlider) then
		GraphicsSlider:SetInteractable(true);
		GraphicsSlider:SetValue(Value);
	end

	SetGraphicsQuality(Value, false);
end

GraphicsMode = MakeSelector(GamePage, "Graphics Mode", ({ "Automatic", "Manual" }), 1, function(Index)
	if (Index == 1) then
		SetGraphicsToAuto();
	else
		SetGraphicsToManual((GraphicsSlider and GraphicsSlider:GetValue()) or GetGraphicsSliderStart());
	end
end)

if (GameSettings.SavedQualityLevel ~= Enum.SavedQualitySetting.Automatic and RenderingSettings.QualityLevel ~= Enum.QualityLevel.Automatic and GameSettings.SavedQualityLevel ~= 0 and RenderingSettings.QualityLevel ~= 0) then
	GraphicsMode:SetSelectionIndex(2);
end

GraphicsSlider = MakeSlider(GamePage, "Graphics Quality", 10, GetGraphicsSliderStart(), function(Value)
	Value = Clamp(Value, 1, 10);
	GraphicsMode:SetSelectionIndex(2);
	GraphicsSlider:SetInteractable(true);
	SetGraphicsQuality(Value, false);
end, 1)

Protect(function()
	Connect(game.GraphicsQualityChangeRequest, function(IsIncrease)
		if (RenderingSettings.QualityLevel == Enum.QualityLevel.Automatic or RenderingSettings.QualityLevel == 0) then
			return
		end

		local Value = Clamp(GraphicsSlider:GetValue() + (IsIncrease and 1 or -1), 1, 10)
		GraphicsMode:SetSelectionIndex(2);
		GraphicsSlider:SetInteractable(true);
		GraphicsSlider:SetValue(Value);
		SetGraphicsQuality(Value, false);
	end)
end)

if (GameSettings.SavedQualityLevel == Enum.SavedQualitySetting.Automatic or RenderingSettings.QualityLevel == Enum.QualityLevel.Automatic or GameSettings.SavedQualityLevel == 0 or RenderingSettings.QualityLevel == 0) then
	SetGraphicsToAuto();
else
	SetGraphicsToManual(GetGraphicsSliderStart());
end

MakeSelector(GamePage, "Haptics", ({ "On", "Off" }), ((GetSetting(GameSettings, "HapticStrength", 1) or 0) > 0 and 1) or 2, function(Index)
	SetSetting(GameSettings, "HapticStrength", (Index == 1 and 1) or 0)
end)
MakeBooleanSelector(GamePage, "Reduce Motion", GameSettings, "ReducedMotion")

local FpsValues = ({ "60", "120", "144", "160", "165", "180", "200", "240" })
local FpsStart = 1
local CurrentFps = tostring(GetSetting(GameSettings, "FramerateCap", 60))
for Index, Value in next, FpsValues do
	if (Value == CurrentFps) then
		FpsStart = Index
	end
end
MakeSelector(GamePage, "Maximum Frame Rate", FpsValues, FpsStart, function(_, Value)
	local Cap = tonumber(Value) or 60
	SetSetting(GameSettings, "FramerateCap", Cap)
	if (setfpscap) then
		Protect(function()
			setfpscap(Cap)
		end)
	end
end)

MakeBooleanSelector(GamePage, "VR", GameSettings, "VREnabled")

local ReportPage = MakePage("ReportAbuse");
AddPage(ReportPage, "Report", "rbxasset://textures/ui/Settings/MenuBarIcons/ReportAbuseTab.png", 150);

local TypeOfAbuse = nil
local WhichPlayer = nil
local NameToPlayer = ({})
local PlayerNames = ({})
local Submit = nil
local SubmitLabel = nil
local Description = nil
local ReportMode = nil

local SetSubmitActive = function(Active)
	if (not Submit or not SubmitLabel) then
		return
	end

	Submit.Selectable = Active
	Submit.ImageTransparency = Active and 0 or 0.65
	Submit.ZIndex = SETTINGS_BASE_ZINDEX + (Active and 3 or 1)
	SubmitLabel.ZIndex = Submit.ZIndex + 1
	SubmitLabel.TextTransparency = Active and 0 or 0.55
end

local GetReportDescription = function()
	local Text = Description and Description.Text or ""

	if (Text == "" or Text == DESCRIPTION_PLACEHOLDER) then
		return REPORT_DESCRIPTION_FALLBACK
	end

	return Text
end

local CanSubmitReport = function(ReportMode)
	if (not TypeOfAbuse or not ReportMode) then
		return false
	end

	if (not TypeOfAbuse:GetSelectedIndex()) then
		return false
	end

	if (ReportMode:GetSelectedIndex() == 2 and (not WhichPlayer or not WhichPlayer:GetSelectedValue())) then
		return false
	end

	return true
end

local RefreshSubmitState = function(ReportMode)
	SetSubmitActive(CanSubmitReport(ReportMode));
end

ReportMode = MakeSelector(ReportPage, "Game or Player?", ({ "Game", "Player" }), 1, function()
	if (not TypeOfAbuse or not WhichPlayer) then
		return
	end

	WhichPlayer:ResetSelectionIndex();
	TypeOfAbuse:ResetSelectionIndex();

	if (ReportMode:GetSelectedIndex() == 1) then
		TypeOfAbuse:UpdateDropDownList(ABUSE_TYPES_GAME);
		WhichPlayer:SetInteractable(false);
	else
		TypeOfAbuse:UpdateDropDownList(ABUSE_TYPES_PLAYER);
		WhichPlayer:SetInteractable(#PlayerNames > 0);
	end

	RefreshSubmitState(ReportMode);
end);
ReportMode:SetSize(UDim2.new(0, 400, 0, 50));
ReportMode:SetPosition(UDim2.new(1, -400, 0.5, -25));

WhichPlayer = MakeDropDown(ReportPage, "Which Player?", PlayerNames, nil, function()
	RefreshSubmitState(ReportMode);
end);
WhichPlayer:SetInteractable(false);

local RefreshReportPlayers = function()
	PlayerNames = ({})
	NameToPlayer = ({})

	for _, Player in next, Players:GetPlayers() do
		if (Player ~= LocalPlayer and (Player.UserId or Player.userId or 0) > 0) then
			Insert(PlayerNames, Player.Name);
			NameToPlayer[Player.Name] = Player
		end
	end

	WhichPlayer:UpdateDropDownList(PlayerNames);
	WhichPlayer:SetInteractable(ReportMode:GetSelectedIndex() == 2 and #PlayerNames > 0);

	if (#PlayerNames == 0 and ReportMode:GetSelectedIndex() == 2) then
		ReportMode:SetSelectionIndex(1, true);
	end

	RefreshSubmitState(ReportMode);
end

OpenReportPlayer = function(Player)
	if (Player and Player ~= LocalPlayer) then
		RefreshReportPlayers();
		ReportMode:SetSelectionIndex(2, true);
		WhichPlayer:SetSelectionByValue(Player.Name, true);

		if (Hub.Visible) then
			SwitchToPage(ReportPage);
		else
			SetVisibility(true, false, ReportPage);
		end
	end
end

Connect(Players.PlayerAdded, RefreshReportPlayers)
Connect(Players.PlayerRemoving, function()
	task.defer(RefreshReportPlayers);
end)

TypeOfAbuse = MakeDropDown(ReportPage, "Type Of Abuse", ABUSE_TYPES_GAME, nil, function()
	RefreshSubmitState(ReportMode);
end);

local DescriptionRow = MakeRow(ReportPage, "");
Description = Create("TextBox", {
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
	Text = DESCRIPTION_PLACEHOLDER,
	Size = UDim2.new(1, -20, 0, 100),
	Position = UDim2.new(0, 10, 0, 0),
	ZIndex = SETTINGS_BASE_ZINDEX + 3,
})
Connect(Description.Focused, function()
	if (Description.Text == DESCRIPTION_PLACEHOLDER) then
		Description.Text = ""
	end
end)
Connect(Description.FocusLost, function()
	if (Description.Text == "") then
		Description.Text = DESCRIPTION_PLACEHOLDER
	end
end)
DescriptionRow.Size = UDim2.new(1, 0, 0, 110);
ReportPage.Frame.Size = UDim2.new(1, 0, 0, ReportPage.Frame.Size.Y.Offset + 60);

Submit, SubmitLabel = MakeStyledButton("SubmitButton", "Submit", UDim2.new(0, 198, 0, 50), function()
	if (not CanSubmitReport(ReportMode)) then
		return
	end

	local IsPlayerReport = ReportMode:GetSelectedIndex() == 2
	local Reason = ((IsPlayerReport and ABUSE_TYPES_PLAYER) or ABUSE_TYPES_GAME)[TypeOfAbuse:GetSelectedIndex()]
	local TargetPlayer = IsPlayerReport and NameToPlayer[WhichPlayer:GetSelectedValue()] or nil
	local DescriptionText = GetReportDescription()

	if (IsPlayerReport and not TargetPlayer) then
		RefreshSubmitState(ReportMode);
		return
	end

	local Success = Protect(function()
		Players.ReportAbuse(LocalPlayer, TargetPlayer, Reason, DescriptionText);
	end)

	if (not Success) then
		Success = Protect(function()
			Players:ReportAbuse(TargetPlayer, Reason, DescriptionText);
		end)
	end

	local AlertText = "Thanks for your report! Our moderators will review the chat logs and evaluate what happened."
	if (Reason == "Cheating/Exploiting") then
		AlertText = "Thanks for your report! We've recorded your report for evaluation."
	elseif (Reason == "Inappropriate Username") then
		AlertText = "Thanks for your report! Our moderators will evaluate the username."
	elseif (Reason == "Bad Model or Script" or Reason == "Inappropriate Content" or Reason == "Offsite Link" or Reason == "Offsite Links") then
		AlertText = "Thanks for your report! Our moderators will review the place and make a determination."
	end

	if (not Success) then
		AlertText = "Report could not be submitted in this environment."
	end

	ShowAlert(AlertText, "Ok", function()
		ReportMode:SetSelectionIndex(1, true);
		WhichPlayer:ResetSelectionIndex();
		TypeOfAbuse:ResetSelectionIndex();
		Description.Text = DESCRIPTION_PLACEHOLDER
		SetVisibility(false);
	end)
end)

Submit.Parent = ReportPage.Frame
Submit.Position = UDim2.new(0.5, -99, 0, ReportPage.Frame.Size.Y.Offset + 10);
ReportPage.Frame.Size = UDim2.new(1, 0, 0, ReportPage.Frame.Size.Y.Offset + 70);
SetSubmitActive(false);
RefreshReportPlayers();

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

local RecordPage = nil
Protect(function()
	local Platform = UserInputService:GetPlatform();

	if (Platform == Enum.Platform.Windows or Platform == Enum.Platform.OSX) then
		RecordPage = MakePage("Record");
		AddPage(RecordPage, "Record", "rbxasset://textures/ui/Settings/MenuBarIcons/RecordTab.png", 130);

		local ScreenshotTitle = MakeText(RecordPage.Frame, "Screenshot", UDim2.new(1, 0, 0, 36), UDim2.new(0, 10, 0.05, 0));
		ScreenshotTitle.TextSize = 36
		ScreenshotTitle.TextXAlignment = Enum.TextXAlignment.Left

		local ScreenshotBody = MakeText(ScreenshotTitle, "By clicking the 'Take Screenshot' button, the menu will close and take a screenshot and save it to your computer.", UDim2.new(1, -10, 0, 70), UDim2.new(0, 0, 1, 0));
		ScreenshotBody.Font = Enum.Font.SourceSans
		ScreenshotBody.TextSize = 24
		ScreenshotBody.TextXAlignment = Enum.TextXAlignment.Left
		ScreenshotBody.TextYAlignment = Enum.TextYAlignment.Top

		local ScreenshotButton = MakeStyledButton("ScreenshotButton", "Take Screenshot", UDim2.new(0, 300, 0, 44), function()
			RunAfterMenuCloses(function()
				pcall(function()
					if (keypress and keyrelease) then
						keypress(KEY_PRINT_SCREEN);
						keyrelease(KEY_PRINT_SCREEN);
					else
						StarterGui:SetCore("TakeScreenshot");
					end
				end)
			end)
		end)
		ScreenshotButton.Parent = ScreenshotBody
		ScreenshotButton.Position = UDim2.new(0, 400, 1, 0);

		local VideoTitle = MakeText(RecordPage.Frame, "Video", UDim2.new(1, 0, 0, 36), UDim2.new(0, 10, 0.5, 0));
		VideoTitle.TextSize = 36
		VideoTitle.TextXAlignment = Enum.TextXAlignment.Left

		local VideoBody = MakeText(VideoTitle, "By clicking the 'Record Video' button, the menu will close and start recording your screen.", UDim2.new(1, -10, 0, 70), UDim2.new(0, 0, 1, 0));
		VideoBody.Font = Enum.Font.SourceSans
		VideoBody.TextSize = 24
		VideoBody.TextXAlignment = Enum.TextXAlignment.Left
		VideoBody.TextYAlignment = Enum.TextYAlignment.Top

		local StartSetting = 2
		Protect(function()
			if (GameSettings.VideoUploadPromptBehavior == Enum.UploadSetting.Never) then
				StartSetting = 1
			end
		end)

		local VideoSettingsMode = MakeSelector(RecordPage, "Video Settings", ({ "Save To Disk", "Upload to YouTube" }), StartSetting, function(Index)
			Protect(function()
				GameSettings.VideoUploadPromptBehavior = (Index == 1 and Enum.UploadSetting.Never) or Enum.UploadSetting.Always;
			end)
		end)

		local LastRow = RecordPage.Rows[#RecordPage.Rows];
		if (LastRow) then
			LastRow.Position = UDim2.new(0, 0, 0, 270);
			VideoSettingsMode:SetPosition(UDim2.new(1, -502, 0.5, -25));
		end

		local RecordButton = MakeStyledButton("RecordButton", "Record Video", UDim2.new(0, 300, 0, 44), function()
			RunAfterMenuCloses(function()
				pcall(function()
					if (keypress and keyrelease) then
						keypress(KEY_F12);
						keyrelease(KEY_F12);
					else
						StarterGui:SetCore("ToggleRecording");
					end
				end)
			end)
		end)
		RecordButton.Parent = LastRow or RecordPage.Frame
		RecordButton.Position = (LastRow and UDim2.new(0, 410, 1, 10)) or UDim2.new(0, 410, 0, 330);
		RecordPage.Frame.Size = UDim2.new(1, 0, 0, 400);
	end
end)

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
	Hub.HubBar.Visible = true
	Hub.BottomButtonFrame.Visible = true
	SwitchToPage(Hub.MenuStack[#Hub.MenuStack] or GamePage, true, true);
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
	Hub.HubBar.Visible = true
	Hub.BottomButtonFrame.Visible = true
	SwitchToPage(Hub.MenuStack[#Hub.MenuStack] or GamePage, true, true);
end)
DontLeaveButton.Parent = LeavePage.Frame
DontLeaveButton.Position = UDim2.new(0.5, 20, 0, 170);
LeavePage.Frame.Size = UDim2.new(1, 0, 0, 240);

local PushPage = function(Page)
	Insert(Hub.MenuStack, GetSelectedPage());
	Hub.HubBar.Visible = false
	Hub.BottomButtonFrame.Visible = false
	SwitchToPage(Page, true, true);
end

local MakeBottomButton = function(Name, Text, Icon, Position, Clicked, Size)
	local Button = MakeStyledButton(Name .. "Button", Text, Size or UDim2.new(0, 260, 0, 70), Clicked);
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
		Label.Position = UDim2.new(0, 10, 0, -4);
		Label.Size = UDim2.new(1, 0, 1, 0);
	end

	return Button
end

local BottomButtonSize = UDim2.new(0, 260, 0, 70)

MakeBottomButton("ResetCharacter", "    Reset Character", "rbxasset://textures/ui/Settings/Help/ResetIcon.png", UDim2.new(0.5, -400, 0.5, -25), function()
	PushPage(ResetPage);
end, BottomButtonSize)

MakeBottomButton("LeaveGame", "Leave Game", "rbxasset://textures/ui/Settings/Help/LeaveIcon.png", UDim2.new(0.5, -130, 0.5, -25), function()
	PushPage(LeavePage);
end, BottomButtonSize)

MakeBottomButton("Resume", "Resume Game", "rbxasset://textures/ui/Settings/Help/EscapeIcon.png", UDim2.new(0.5, 140, 0.5, -25), function()
	SetVisibility(false);
end, BottomButtonSize)

local HideNativeSettingsMenu = function()
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui");
	local Shield = RobloxGui and RobloxGui:FindFirstChild("SettingsClippingShield");

	if (Shield) then
		for _, Child in next, Shield:GetDescendants() do
			if (Child.Name == "SettingsShield" and Child ~= Hub.Shield) then
				pcall(function()
					Child.Visible = false
				end)
				pcall(function()
					Child.BackgroundTransparency = 1
				end)
			end
		end
	end
end

local INPUT_LOCK_ACTION = "Settings2016InputLock"
local InputLockBound = false
local InputLockInputs = ({})
local InputLockActions = ({})
local SavedMouseBehavior = nil

local AddInputLock = function(EnumName, Name)
	Protect(function()
		local EnumType = Enum[EnumName]
		local Item = EnumType and EnumType[Name]
		if (Item) then
			Insert(InputLockInputs, Item);
		end
	end)
end

AddInputLock("PlayerActions", "CharacterForward")
AddInputLock("PlayerActions", "CharacterBackward")
AddInputLock("PlayerActions", "CharacterLeft")
AddInputLock("PlayerActions", "CharacterRight")
AddInputLock("PlayerActions", "CharacterJump")
AddInputLock("KeyCode", "W")
AddInputLock("KeyCode", "A")
AddInputLock("KeyCode", "S")
AddInputLock("KeyCode", "D")
AddInputLock("KeyCode", "Space")
AddInputLock("KeyCode", "LeftShift")
AddInputLock("KeyCode", "RightShift")
AddInputLock("KeyCode", "Thumbstick1")
AddInputLock("KeyCode", "Thumbstick2")

local SinkGameplayInput = function()
	local FocusedTextBox = nil
	Protect(function()
		FocusedTextBox = UserInputService:GetFocusedTextBox();
	end)

	if (FocusedTextBox) then
		return Enum.ContextActionResult.Pass
	end

	return Enum.ContextActionResult.Sink
end

local SetGameplayInputLocked = function(Locked)
	if (InputLockBound == Locked) then
		return
	end

	InputLockBound = Locked

	if (Locked) then
		Protect(function()
			SavedMouseBehavior = UserInputService.MouseBehavior
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)

		InputLockActions = ({})

		for Index, Input in next, InputLockInputs do
			local ActionName = INPUT_LOCK_ACTION .. tostring(Index)
			local Bound = Protect(function()
				ContextActionService:BindCoreActionAtPriority(ActionName, SinkGameplayInput, false, 10000, Input);
			end)

			if (not Bound) then
				Bound = Protect(function()
					ContextActionService:BindCoreAction(ActionName, SinkGameplayInput, false, Input);
				end)
			end

			if (not Bound) then
				Bound = Protect(function()
					ContextActionService:BindActionAtPriority(ActionName, SinkGameplayInput, false, 10000, Input);
				end)
			end

			if (Bound) then
				Insert(InputLockActions, ActionName);
			end
		end
	else
		for _, ActionName in next, InputLockActions do
			Protect(function()
				ContextActionService:UnbindCoreAction(ActionName);
			end)
			Protect(function()
				ContextActionService:UnbindAction(ActionName);
			end)
		end
		InputLockActions = ({})

		Protect(function()
			if (SavedMouseBehavior) then
				UserInputService.MouseBehavior = SavedMouseBehavior
			end
			SavedMouseBehavior = nil
		end)
	end
end

SetVisibility = function(Visible, NoAnimation, CustomPage)
	if (Hub.Visible == Visible and not CustomPage) then
		return
	end

	Hub.Visible = Visible
	Hub.Modal.Visible = Visible
	SetGameplayInputLocked(Visible);

	if (Visible) then
		HideNativeSettingsMenu();
		Hub.Shield.Visible = true
		Hub.HubBar.Visible = true
		Hub.PageClipper.Visible = true
		Hub.BottomButtonFrame.Visible = true

		if (NoAnimation) then
			Hub.Shield.Position = SETTINGS_ACTIVE_POSITION
		else
			Hub.Shield.Position = SETTINGS_INACTIVE_POSITION
			TweenTo(Hub.Shield, SETTINGS_ACTIVE_POSITION, Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5);
		end

		SwitchToPage(CustomPage or PlayersPage, true);
	else
		if (NoAnimation) then
			Hub.Shield.Position = SETTINGS_INACTIVE_POSITION
			Hub.Shield.Visible = false
		else
			TweenTo(Hub.Shield, SETTINGS_INACTIVE_POSITION, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.4, function()
				if (not Hub.Visible) then
					Hub.Shield.Visible = false
				end
			end)
		end
	end
end

local ToggleVisibility = function()
	SetVisibility(not Hub.Visible);
end

SwitchToPage(GamePage, true);

local LastEscapeAction = 0
local EscapeAction = function(_, State)
	if (State ~= Enum.UserInputState.Begin) then
		return Enum.ContextActionResult.Sink
	end

	local Now = tick()
	if ((Now - LastEscapeAction) < 0.15) then
		return Enum.ContextActionResult.Sink
	end
	LastEscapeAction = Now

	HideNativeSettingsMenu();
	local WasVisible = Hub.Visible

	if (Hub.Visible and (Hub.CurrentPage == ResetPage or Hub.CurrentPage == LeavePage)) then
		Hub.HubBar.Visible = true
		Hub.BottomButtonFrame.Visible = true
		SwitchToPage(Hub.MenuStack[#Hub.MenuStack] or GamePage, true, true);
	else
		if (WasVisible) then
			Hub.SuppressNativeOpenUntil = Now + 0.8
		end

		ToggleVisibility();
	end

	Spawn(function()
		Wait();
		HideNativeSettingsMenu();
	end)

	return Enum.ContextActionResult.Sink
end

Protect(function()
	local BoundAtPriority = pcall(function()
		ContextActionService:BindCoreActionAtPriority("RBXEscapeMainMenu", EscapeAction, false, 10000, Enum.KeyCode.Escape, Enum.KeyCode.ButtonStart);
	end)

	if (not BoundAtPriority) then
		ContextActionService:BindCoreAction("RBXEscapeMainMenu", EscapeAction, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonStart);
	end
end)

Connect(UserInputService.InputBegan, function(Input, Processed)
	if (Processed and Input.KeyCode ~= Enum.KeyCode.Escape) then
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
	local HookedNative = {}

	local HookNativeShield = function(Native)
		if (not Native or HookedNative[Native]) then
			return
		end

		HookedNative[Native] = true
		Connect(Native:GetPropertyChangedSignal("Visible"), function()
			if (Native.Visible) then
				HideNativeSettingsMenu();
				if (tick() < Hub.SuppressNativeOpenUntil) then
					return
				end

				SetVisibility((Hub.NativeMenuTarget ~= nil and Hub.NativeMenuTarget) or true);
				Hub.NativeMenuTarget = nil
			end
		end)

		if (Native.Visible) then
			HideNativeSettingsMenu();
			if (tick() < Hub.SuppressNativeOpenUntil) then
				return
			end

			SetVisibility(true);
		end
	end

	local RobloxGui = CoreGui:FindFirstChild("RobloxGui");
	local Shield = RobloxGui and RobloxGui:FindFirstChild("SettingsClippingShield");
	local Native = Shield and Shield:FindFirstChild("SettingsShield");

	HookNativeShield(Native);

	if (RobloxGui) then
		Connect(RobloxGui.DescendantAdded, function(Descendant)
			if (Descendant.Name == "SettingsShield" and Descendant.Parent and Descendant.Parent.Name == "SettingsClippingShield") then
				HookNativeShield(Descendant);
			end
		end)
	end

	local TopBarApp = CoreGui:FindFirstChild("TopBarApp");
	TopBarApp = TopBarApp and TopBarApp:FindFirstChild("TopBarApp");
	local Holder = TopBarApp and TopBarApp:FindFirstChild("MenuIconHolder");
	local Hit = Holder and Holder:FindFirstChild("TriggerPoint") and Holder.TriggerPoint:FindFirstChild("IconHitArea");

	if (Hit and Hit:IsA("GuiButton")) then
		Connect(Hit.MouseButton1Click, function()
			local Target = not Hub.Visible
			Hub.NativeMenuTarget = Target
			Spawn(function()
				Wait();
				SetVisibility(Target);
				if (Hub.NativeMenuTarget == Target) then
					Hub.NativeMenuTarget = nil
				end
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
	if (OpenReportPlayer) then
		OpenReportPlayer(Player);
	end
end

Api.Instance = Hub
getgenv().Settings2016 = Api

return Api
