local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FrutyLib = {
	Flags = {},
	Connections = {},
	Folder = nil,
	SaveCfgEnabled = false,
	ActiveRows = nil,
	Destroyed = false,
}

local T = {
	BG      = Color3.fromRGB(15, 16, 19),
	Rail    = Color3.fromRGB(12, 13, 16),
	Card    = Color3.fromRGB(21, 22, 27),
	Hover   = Color3.fromRGB(27, 28, 34),
	Border  = Color3.fromRGB(42, 43, 49),
	Divider = Color3.fromRGB(34, 35, 42),
	Accent  = Color3.fromRGB(217, 56, 62),
	Accent2 = Color3.fromRGB(224, 57, 63),
	Text    = Color3.fromRGB(201, 203, 211),
	Muted   = Color3.fromRGB(154, 156, 166),
	White   = Color3.fromRGB(242, 242, 245),
	Off     = Color3.fromRGB(58, 60, 68),
	Search  = Color3.fromRGB(23, 24, 29),
	Blue    = Color3.fromRGB(61, 165, 255),
}

local function Tween(obj, props, speed)
	local t = TweenService:Create(obj, TweenInfo.new(speed or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function Create(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = obj end
	return obj
end

local function Corner(r)
	return Create("UICorner", {CornerRadius = UDim.new(0, r or 6)})
end

local function Stroke(color, th, transparency)
	return Create("UIStroke", {Color = color or T.Border, Thickness = th or 1, Transparency = transparency or 0})
end

local function MakeLabel(text, size, color, bold, props)
	local l = Create("TextLabel", {
		Text = text or "",
		TextSize = size or 14,
		TextColor3 = color or T.Text,
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end

local IconParts = setmetatable({}, {__mode = "k"})

local function DrawIcon(name, size, color)
	color = color or T.Muted
	local holder = Create("Frame", {
		Size = UDim2.new(0, size, 0, size),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	local th = math.max(1.6, size / 8)
	local s = size
	local parts = {}
	IconParts[holder] = parts

	local function ring(d, xoff, yoff)
		local r = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, xoff or 0, 0.5, yoff or 0),
			Size = UDim2.new(0, d, 0, d),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
			Create("UIStroke", {Color = color, Thickness = th}),
		})
		r.Parent = holder
		table.insert(parts, r:FindFirstChildOfClass("UIStroke"))
		return r
	end

	local function bar(len, thick, rot, xoff, yoff)
		local b = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, xoff or 0, 0.5, yoff or 0),
			Size = UDim2.new(0, len, 0, thick or th),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Rotation = rot or 0,
		}, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
		b.Parent = holder
		table.insert(parts, b)
		return b
	end

	local function dot(d, xoff, yoff)
		return bar(d, d, 0, xoff, yoff)
	end

	if name == "crosshair" then
		ring(s * 0.6)
		bar(s * 0.22, th, 0, 0, -s * 0.38)
		bar(s * 0.22, th, 0, 0, s * 0.38)
		bar(s * 0.22, th, 90, -s * 0.38, 0)
		bar(s * 0.22, th, 90, s * 0.38, 0)
		dot(s * 0.14)
	elseif name == "eye" then
		ring(s * 0.74)
		dot(s * 0.3)
	elseif name == "skull" then
		ring(s * 0.76)
		dot(s * 0.17, -s * 0.16, -s * 0.08)
		dot(s * 0.17, s * 0.16, -s * 0.08)
		bar(s * 0.26, th, 0, 0, s * 0.2)
	elseif name == "search" then
		ring(s * 0.6, -s * 0.09, -s * 0.09)
		bar(s * 0.4, th, 45, s * 0.2, s * 0.2)
	elseif name == "chevron-down" then
		bar(s * 0.5, th, 45, -s * 0.12, -s * 0.06)
		bar(s * 0.5, th, -45, s * 0.12, -s * 0.06)
	elseif name == "chevron-right" then
		bar(s * 0.5, th, -45, -s * 0.06, -s * 0.12)
		bar(s * 0.5, th, 45, -s * 0.06, s * 0.12)
	elseif name == "x" then
		bar(s * 0.64, th, 45)
		bar(s * 0.64, th, -45)
	elseif name == "minus" then
		bar(s * 0.64, th, 0)
	elseif name == "plus" then
		bar(s * 0.64, th, 0)
		bar(s * 0.64, th, 90)
	else
		dot(s * 0.3)
	end
	return holder
end

local function MakeIcon(name, size, color)
	if type(name) == "string" and name:sub(1, 12) == "rbxassetid://" then
		return Create("ImageLabel", {
			Image = name, ImageColor3 = color or T.Muted,
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(0, size, 0, size),
		})
	end
	return DrawIcon(name, size, color)
end

local function Track(conn)
	table.insert(FrutyLib.Connections, conn)
	return conn
end

local function Round(n, f)
	f = f or 1
	return math.floor(n / f + 0.5) * f
end

function FrutyLib:SaveConfig()
	if not FrutyLib.SaveCfgEnabled then return end
	pcall(function()
		local data = {}
		for k, v in pairs(FrutyLib.Flags) do
			if v.Save then
				if v.Type == "ColorPicker" then
					data[k] = {R = math.floor(v.Value.R * 255 + 0.5), G = math.floor(v.Value.G * 255 + 0.5), B = math.floor(v.Value.B * 255 + 0.5)}
				else
					data[k] = v.Value
				end
			end
		end
		writefile(FrutyLib.Folder .. "/" .. game.GameId .. ".txt", HttpService:JSONEncode(data))
	end)
end

function FrutyLib:MakeNotification(C)
	C = C or {}
	task.spawn(function()
		if FrutyLib.Destroyed or not FrutyLib.Gui then return end
		C.Name = C.Name or "Notification"
		C.Content = C.Content or ""
		C.Time = C.Time or 5

		local wrap = Create("Frame", {
			Parent = FrutyLib.NotifHolder,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 330, 0, 0),
		})

		local card = Create("Frame", {
			Parent = wrap,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = T.Card,
			BorderSizePixel = 0,
		}, {Corner(8), Stroke(T.Border, 1)})

		Create("Frame", {Parent = card, Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0}, {Corner(2)})

		local title = MakeLabel(C.Name, 14, T.White, true, {Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 16)})
		title.Parent = card

		local content = MakeLabel(C.Content, 13, T.Muted, false, {
			Position = UDim2.new(0, 14, 0, 30),
			Size = UDim2.new(1, -28, 0, 16),
			TextWrapped = true,
		})
		content.Parent = card

		Track(content:GetPropertyChangedSignal("Text"):Connect(function()
			card.Size = UDim2.new(1, 0, 0, content.TextBounds.Y + 40)
		end))
		task.defer(function()
			card.Size = UDim2.new(1, 0, 0, content.TextBounds.Y + 40)
		end)

		Tween(wrap, {Position = UDim2.new(0, 0, 0, 0)}, 0.4)

		task.wait(C.Time)
		if FrutyLib.Destroyed then return end
		Tween(wrap, {Position = UDim2.new(0, 330, 0, 0)}, 0.35)
		task.wait(0.35)
		wrap:Destroy()
	end)
end

function FrutyLib:MakeWindow(Config)
	Config = Config or {}
	Config.Name = Config.Name or "Fruty Library"
	Config.ConfigFolder = Config.ConfigFolder or Config.Name
	Config.SaveConfig = Config.SaveConfig or false
	FrutyLib.Folder = Config.ConfigFolder
	FrutyLib.SaveCfgEnabled = Config.SaveConfig

	if Config.SaveConfig then
		pcall(function()
			if not isfolder(Config.ConfigFolder) then makefolder(Config.ConfigFolder) end
		end)
	end

	local Fruty = Create("ScreenGui", {
		Name = "FrutyV2_" .. tostring(math.random(100000, 999999)),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999999,
	})
	FrutyLib.Gui = Fruty

	if syn and syn.protect_gui then pcall(syn.protect_gui, Fruty) end
	local ok = pcall(function()
		Fruty.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not Fruty.Parent then
		Fruty.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	pcall(function()
		for _, g in ipairs(Fruty.Parent:GetChildren()) do
			if g ~= Fruty and g.Name:sub(1, 8) == "FrutyV2_" then g:Destroy() end
		end
	end)

	FrutyLib.NotifHolder = Create("Frame", {
		Parent = Fruty,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 0, 500),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, {
		Create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
	})

	local FullSize = UDim2.fromOffset(700, 430)
	local MainWindow = Create("Frame", {
		Parent = Fruty,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(679, 417),
		BackgroundColor3 = T.BG,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {Corner(10), Stroke(T.Border, 1)})
	FrutyLib.Window = MainWindow

	local TopBar = Create("Frame", {
		Parent = MainWindow,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = T.Rail,
		BorderSizePixel = 0,
	})

	local Logo = Create("Frame", {
		Parent = TopBar,
		Position = UDim2.new(0, 14, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = T.Accent,
		BorderSizePixel = 0,
	}, {Corner(7)})
	MakeLabel("F", 16, T.White, true, {Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center}).Parent = Logo

	MakeLabel(Config.Name, 15, T.White, true, {Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -160, 1, 0)}).Parent = TopBar

	Create("Frame", {Parent = TopBar, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Divider, BorderSizePixel = 0}).Parent = TopBar

	local function TweenIco(ico, color)
		local parts = IconParts[ico]
		if parts then
			for _, obj in ipairs(parts) do
				if obj:IsA("UIStroke") then
					Tween(obj, {Color = color}, 0.18)
				else
					Tween(obj, {BackgroundColor3 = color}, 0.18)
				end
			end
		elseif ico and ico:IsA("ImageLabel") then
			Tween(ico, {ImageColor3 = color}, 0.18)
		elseif ico then
			Tween(ico, {TextColor3 = color}, 0.18)
		end
	end

	local function TopBtn(name, xPos)
		local b = Create("TextButton", {
			Parent = TopBar,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xPos, 0.5, 0),
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundColor3 = T.Card,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, {Corner(7)})
		local ico = MakeIcon(name, 15, T.Muted)
		ico.AnchorPoint = Vector2.new(0.5, 0.5)
		ico.Position = UDim2.new(0.5, 0, 0.5, 0)
		ico.Parent = b
		local alt
		if name == "minus" then
			alt = MakeIcon("plus", 15, T.Muted)
			alt.AnchorPoint = Vector2.new(0.5, 0.5)
			alt.Position = UDim2.new(0.5, 0, 0.5, 0)
			alt.Visible = false
			alt.Parent = b
		end
		b.MouseEnter:Connect(function()
			Tween(b, {BackgroundColor3 = T.Hover})
			TweenIco(ico, T.White)
			if alt then TweenIco(alt, T.White) end
		end)
		b.MouseLeave:Connect(function()
			Tween(b, {BackgroundColor3 = T.Card})
			TweenIco(ico, T.Muted)
			if alt then TweenIco(alt, T.Muted) end
		end)
		return b, ico, alt
	end

	local CloseBtn, CloseIco = TopBtn("x", -12)
	local MinBtn, MinIco, MinAlt = TopBtn("minus", -48)

	local DragPoint = Create("TextButton", {
		Parent = TopBar,
		Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local Sidebar = Create("Frame", {
		Parent = MainWindow,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(0, 190, 1, -44),
		BackgroundColor3 = T.Rail,
		BorderSizePixel = 0,
	})
	Create("Frame", {Parent = Sidebar, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Divider, BorderSizePixel = 0})

	local Content = Create("Frame", {
		Parent = MainWindow,
		Position = UDim2.new(0, 190, 0, 44),
		Size = UDim2.new(1, -190, 1, -44),
		BackgroundTransparency = 1,
	})

	local TabTitle = MakeLabel("", 16, T.White, true, {Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0, 200, 0, 44)})
	TabTitle.Parent = Content

	local SearchFrame = Create("Frame", {
		Parent = Content,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, 22),
		Size = UDim2.new(0, 170, 0, 28),
		BackgroundColor3 = T.Search,
		BorderSizePixel = 0,
	}, {Corner(6)})
	local SearchStroke = Stroke(T.Border, 1)
	SearchStroke.Parent = SearchFrame

	local SearchIco = MakeIcon("search", 13, T.Muted)
	SearchIco.Position = UDim2.new(0, 9, 0.5, 0)
	SearchIco.AnchorPoint = Vector2.new(0, 0.5)
	SearchIco.Parent = SearchFrame

	local SearchBox = Create("TextBox", {
		Parent = SearchFrame,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = T.Muted,
		TextColor3 = T.White,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})

	SearchBox.Focused:Connect(function() Tween(SearchStroke, {Color = T.Accent}, 0.15) end)
	SearchBox.FocusLost:Connect(function() Tween(SearchStroke, {Color = T.Border}, 0.15) end)

	local function ApplySearch(Q)
		local rows = FrutyLib.ActiveRows
		if not rows then return end
		Q = string.lower(Q or "")
		for _, r in ipairs(rows) do
			if Q == "" then
				r.Frame.Visible = true
			else
				r.Frame.Visible = string.find(r.Text, Q, 1, true) ~= nil
			end
		end
	end

	Track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		ApplySearch(SearchBox.Text)
	end))

	do
		local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = Input.Position
				startPos = MainWindow.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = Input end
		end)
		Track(UserInputService.InputChanged:Connect(function(Input)
			if Input == dragInput and dragging then
				local Delta = Input.Position - dragStart
				MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
			end
		end))
	end

	Track(UserInputService.InputBegan:Connect(function(Input, gpe)
		if gpe then return end
		if Input.KeyCode == Enum.KeyCode.RightShift or Input.KeyCode == Enum.KeyCode.Insert then
			MainWindow.Visible = not MainWindow.Visible
		end
	end))

	local Minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		Minimized = not Minimized
		MinIco.Visible = not Minimized
		MinAlt.Visible = Minimized
		if Minimized then
			Sidebar.Visible = false
			Content.Visible = false
			Tween(MainWindow, {Size = UDim2.new(0, 260, 0, 44)}, 0.3)
		else
			Sidebar.Visible = true
			Content.Visible = true
			Tween(MainWindow, {Size = FullSize}, 0.3)
		end
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		MainWindow.Visible = false
		FrutyLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Press RightShift or Insert to reopen.",
			Time = 4,
		})
	end)

	local Tabs = {}
	local FirstTab = true

	local TabHolder = Create("ScrollingFrame", {
		Parent = Sidebar,
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Divider,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, {
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)}),
		Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4)}),
	})

	local function SelectTab(Tab)
		for _, tb in ipairs(Tabs) do
			tb.Bar.Visible = false
			Tween(tb.Button, {BackgroundColor3 = T.Rail}, 0.18)
			TweenIco(tb.Ico, T.Muted)
			Tween(tb.Title, {TextColor3 = T.Muted}, 0.18)
			tb.Container.Visible = false
		end
		Tab.Bar.Visible = true
		Tween(Tab.Button, {BackgroundColor3 = T.Hover}, 0.18)
		TweenIco(Tab.Ico, T.Accent2)
		Tween(Tab.Title, {TextColor3 = T.White}, 0.18)
		Tab.Container.Visible = true
		TabTitle.Text = Tab.Name
		FrutyLib.ActiveRows = Tab.Rows
		ApplySearch(SearchBox.Text)
	end

	local PlayerCard = Create("Frame", {
		Parent = Sidebar,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(1, -20, 0, 36),
		BackgroundColor3 = T.Card,
		BorderSizePixel = 0,
	}, {Corner(7)})
	local Avatar = Create("ImageLabel", {
		Parent = PlayerCard,
		Position = UDim2.new(0, 4, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundTransparency = 1,
		Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png",
	}, {Corner(14)})
	MakeLabel(LocalPlayer.DisplayName, 13, T.White, true, {Position = UDim2.new(0, 38, 0, 3), Size = UDim2.new(1, -42, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd}).Parent = PlayerCard
	MakeLabel("@" .. LocalPlayer.Name, 11, T.Muted, false, {Position = UDim2.new(0, 38, 0, 18), Size = UDim2.new(1, -42, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd}).Parent = PlayerCard

	local Window = {}

	function Window:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		local TabName = TabConfig.Name or "Tab"

		local Btn = Create("TextButton", {
			Parent = TabHolder,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = T.Rail,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, {Corner(7)})

		local Bar = Create("Frame", {
			Parent = Btn,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 14),
			BackgroundColor3 = T.Accent,
			BorderSizePixel = 0,
			Visible = false,
		}, {Corner(2)})

		local Ico = MakeIcon(TabConfig.Icon or "circle", 16, T.Muted)
		Ico.AnchorPoint = Vector2.new(0, 0.5)
		Ico.Position = UDim2.new(0, 10, 0.5, 0)
		Ico.Parent = Btn

		local Title = MakeLabel(TabName, 14, T.Muted, false, {
			Position = UDim2.new(0, 34, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		Title.Parent = Btn

		local Container = Create("ScrollingFrame", {
			Parent = Content,
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(1, 0, 1, -44),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Divider,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
		}, {
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}),
			Create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)}),
		})

		Track(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 20)
		end))

		local Tab = {Name = TabName, Button = Btn, Ico = Ico, Title = Title, Bar = Bar, Container = Container, Rows = {}}
		table.insert(Tabs, Tab)

		Btn.MouseButton1Click:Connect(function()
			SelectTab(Tab)
		end)

		if FirstTab then
			FirstTab = false
			SelectTab(Tab)
		end

		local rows = Tab.Rows
		local container = Container
		local ElementFunction = {}

		local function NewRow(height)
			local row = Create("TextButton", {
				Parent = container,
				Size = UDim2.new(1, 0, 0, height or 36),
				BackgroundColor3 = T.Card,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
			}, {Corner(6)})
			row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = T.Hover}) end)
			row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = T.Card}) end)
			return row
		end

		local function RowLabel(row, Text)
			local l = MakeLabel(Text, 14, T.Text, false, {
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -120, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			l.Parent = row
			return l
		end

		local function Register(row, Text)
			table.insert(rows, {Frame = row, Text = string.lower(Text)})
		end

		local function SaveIfEnabled()
			FrutyLib:SaveConfig()
		end

		function ElementFunction:AddToggle(C)
			C = C or {}
			local Name = C.Name or "Toggle"
			local Color = C.Color or T.Accent2
			local Toggle = {Value = C.Default or false, Type = "Toggle", Save = C.Save or false}
			local Callback = C.Callback or function() end

			local row = NewRow(36)
			RowLabel(row, Name)

			local pill = Create("Frame", {
				Parent = row,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 40, 0, 22),
				BackgroundColor3 = T.Off,
				BorderSizePixel = 0,
			}, {Corner(11)})
			local knob = Create("Frame", {
				Parent = pill,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 11, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = T.White,
				BorderSizePixel = 0,
			}, {Corner(8)})

			function Toggle:Set(v)
				Toggle.Value = v and true or false
				Tween(pill, {BackgroundColor3 = Toggle.Value and Color or T.Off}, 0.25)
				Tween(knob, {Position = Toggle.Value and UDim2.new(0, 29, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)}, 0.25)
				Callback(Toggle.Value)
			end

			row.MouseButton1Click:Connect(function()
				Toggle:Set(not Toggle.Value)
				SaveIfEnabled()
			end)

			Toggle:Set(Toggle.Value)
			if C.Flag then FrutyLib.Flags[C.Flag] = Toggle end
			Register(row, Name)
			return Toggle
		end

		function ElementFunction:AddSlider(C)
			C = C or {}
			local Name = C.Name or "Slider"
			local Min = C.Min or 0
			local Max = C.Max or 100
			local Increment = C.Increment or 1
			local ValueName = C.ValueName or ""
			local Color = C.Color or T.Accent2
			local Callback = C.Callback or function() end
			local Slider = {Value = C.Default or Min, Type = "Slider", Save = C.Save or false}

			local row = NewRow(46)
			MakeLabel(Name, 14, T.Text, false, {Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 0, 28)}).Parent = row
			local value = MakeLabel(tostring(Slider.Value) .. " " .. ValueName, 12, T.Muted, false, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 0),
				Size = UDim2.new(0, 90, 0, 28),
				TextXAlignment = Enum.TextXAlignment.Right,
			})
			value.Parent = row

			local bar = Create("Frame", {
				Parent = row,
				Position = UDim2.new(0, 12, 0, 34),
				Size = UDim2.new(1, -24, 0, 4),
				BackgroundColor3 = T.Off,
				BorderSizePixel = 0,
				Active = true,
			}, {Corner(2)})
			local fill = Create("Frame", {
				Parent = bar,
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Color,
				BorderSizePixel = 0,
			}, {Corner(2)})
			local knob = Create("Frame", {
				Parent = row,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 12, 0, 36),
				Size = UDim2.new(0, 12, 0, 12),
				BackgroundColor3 = T.White,
				BorderSizePixel = 0,
			}, {Corner(6)})

			local dragging = false
			local function SetFromX(x)
				local pct = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
				Slider:Set(Min + (Max - Min) * pct)
			end

			Track(bar.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					SetFromX(Input.Position.X)
				end
			end))
			Track(UserInputService.InputChanged:Connect(function(Input)
				if dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
					SetFromX(Input.Position.X)
				end
			end))
			Track(UserInputService.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
			end))

			function Slider:Set(v)
				v = math.clamp(Round(v, Increment), Min, Max)
				Slider.Value = v
				local pct = (v - Min) / (Max - Min)
				fill.Size = UDim2.fromScale(pct, 1)
				knob.Position = UDim2.new(pct, 12, 0, 36)
				value.Text = tostring(v) .. " " .. ValueName
				Callback(v)
			end

			Slider:Set(Slider.Value)
			if C.Flag then FrutyLib.Flags[C.Flag] = Slider end
			Register(row, Name)
			return Slider
		end

		function ElementFunction:AddButton(C)
			C = C or {}
			local Name = C.Name or "Button"
			local Callback = C.Callback or function() end

			local row = NewRow(36)
			RowLabel(row, Name)
			local ico = MakeIcon("chevron-right", 15, T.Muted)
			ico.AnchorPoint = Vector2.new(1, 0.5)
			ico.Position = UDim2.new(1, -14, 0.5, 0)
			ico.Parent = row

			row.MouseButton1Click:Connect(function()
				Tween(row, {BackgroundColor3 = T.Accent}, 0.12)
				task.delay(0.12, function() Tween(row, {BackgroundColor3 = T.Card}, 0.2) end)
				task.spawn(Callback)
			end)

			Register(row, Name)
			return {Set = function(Text) row:FindFirstChildOfClass("TextLabel").Text = Text end}
		end

		function ElementFunction:AddDropdown(C)
			C = C or {}
			local Name = C.Name or "Dropdown"
			local Options = C.Options or {}
			local Callback = C.Callback or function() end
			local MaxVisible = 6
			local Dropdown = {Value = C.Default or "", Options = Options, Buttons = {}, Open = false, Type = "Dropdown", Save = C.Save or false}

			local row = NewRow(36)
			row.ClipsDescendants = true
			RowLabel(row, Name)
			local selected = MakeLabel(Dropdown.Value, 13, T.Muted, false, {
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -70, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			selected.Parent = row
			local ico = MakeIcon("chevron-down", 14, T.Muted)
			ico.AnchorPoint = Vector2.new(1, 0.5)
			ico.Position = UDim2.new(1, -14, 0.5, 0)
			ico.Parent = row

			local list = Create("Frame", {
				Parent = row,
				Position = UDim2.new(0, 8, 0, 42),
				Size = UDim2.new(1, -16, 0, 0),
				BackgroundTransparency = 1,
			}, {
				Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}),
			})

			local function UpdateSize()
				if Dropdown.Open then
					local innerH = math.min(#Dropdown.Options, MaxVisible) * 30
					row.Size = UDim2.new(1, 0, 0, 46 + innerH + 6)
				else
					row.Size = UDim2.new(1, 0, 0, 36)
				end
			end

			local function AddOptions(opts)
				for _, opt in ipairs(opts) do
					local ob = Create("TextButton", {
						Parent = list,
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = T.Hover,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
					}, {Corner(5)})
					local ol = MakeLabel(tostring(opt), 13, T.Muted, false, {Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
					ol.Parent = ob
					ob.MouseEnter:Connect(function() Tween(ob, {BackgroundTransparency = 0.6}, 0.12) end)
					ob.MouseLeave:Connect(function() Tween(ob, {BackgroundTransparency = 1}, 0.12) end)
					ob.MouseButton1Click:Connect(function()
						Dropdown:Set(opt)
						SaveIfEnabled()
					end)
					Dropdown.Buttons[opt] = {Button = ob, Label = ol}
				end
			end

			function Dropdown:Refresh(opts, delete)
				if delete then
					for _, b in pairs(Dropdown.Buttons) do b.Button:Destroy() end
					table.clear(Dropdown.Buttons)
				end
				Dropdown.Options = opts
				AddOptions(opts)
				Dropdown:Set(Dropdown.Value)
				UpdateSize()
			end

			function Dropdown:Set(v)
				if not table.find(Dropdown.Options, v) then
					Dropdown.Value = ""
					selected.Text = "..."
					return
				end
				Dropdown.Value = v
				selected.Text = tostring(v)
				for opt, b in pairs(Dropdown.Buttons) do
					Tween(b.Label, {TextColor3 = (opt == v) and T.White or T.Muted}, 0.15)
				end
				Callback(v)
			end

			row.MouseButton1Click:Connect(function()
				Dropdown.Open = not Dropdown.Open
				UpdateSize()
				Tween(ico, {Rotation = Dropdown.Open and 180 or 0}, 0.2)
			end)

			AddOptions(Options)
			Dropdown:Set(Dropdown.Value)
			if C.Flag then FrutyLib.Flags[C.Flag] = Dropdown end
			Register(row, Name)
			return Dropdown
		end

		local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

		local function IsBlacklisted(key)
			for _, v in ipairs(BlacklistedKeys) do
				if v == key then return true end
			end
			return false
		end

		function ElementFunction:AddBind(C)
			C = C or {}
			local Name = C.Name or "Bind"
			local Hold = C.Hold or false
			local Callback = C.Callback or function() end
			local Bind = {Value = nil, Binding = false, Holding = false, Type = "Bind", Save = C.Save or false}

			local row = NewRow(36)
			RowLabel(row, Name)

			local box = Create("Frame", {
				Parent = row,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 70, 0, 24),
				BackgroundColor3 = T.Search,
				BorderSizePixel = 0,
			}, {Corner(6), Stroke(T.Border, 1)})
			local bl = MakeLabel("none", 12, T.Muted, false, {Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center})
			bl.Parent = box

			function Bind:Set(k)
				Bind.Binding = false
				if k ~= nil then Bind.Value = k end
				bl.Text = Bind.Value and (Bind.Value.Name or tostring(Bind.Value)) or "none"
			end

			row.MouseButton1Click:Connect(function()
				if Bind.Binding then return end
				Bind.Binding = true
				bl.Text = "..."
			end)

			Track(UserInputService.InputBegan:Connect(function(Input, gpe)
				if gpe then return end
				if Bind.Binding then
					if Input.KeyCode == Enum.KeyCode.Escape then
						Bind.Binding = false
						bl.Text = Bind.Value and Bind.Value.Name or "none"
						return
					end
					local key
					if not IsBlacklisted(Input.KeyCode) then key = Input.KeyCode end
					if not key and (Input.UserInputType == Enum.UserInputType.MouseButton2 or Input.UserInputType == Enum.UserInputType.MouseButton3) then
						key = Input.UserInputType
					end
					Bind:Set(key)
					SaveIfEnabled()
				elseif Bind.Value and (Input.KeyCode == Bind.Value or Input.UserInputType == Bind.Value) then
					if Hold then
						Bind.Holding = true
						Callback(true)
					else
						Callback()
					end
				end
			end))

			Track(UserInputService.InputEnded:Connect(function(Input)
				if Hold and Bind.Holding and Bind.Value and (Input.KeyCode == Bind.Value or Input.UserInputType == Bind.Value) then
					Bind.Holding = false
					Callback(false)
				end
			end))

			Bind:Set(C.Default)
			if C.Flag then FrutyLib.Flags[C.Flag] = Bind end
			Register(row, Name)
			return Bind
		end

		function ElementFunction:AddTextbox(C)
			C = C or {}
			local Name = C.Name or "Textbox"
			local Callback = C.Callback or function() end
			local Disappear = C.TextDisappear or false

			local row = NewRow(36)
			RowLabel(row, Name)

			local box = Create("Frame", {
				Parent = row,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 160, 0, 24),
				BackgroundColor3 = T.Search,
				BorderSizePixel = 0,
			}, {Corner(6), Stroke(T.Border, 1)})
			local input = Create("TextBox", {
				Parent = box,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				PlaceholderText = "Input",
				PlaceholderColor3 = T.Muted,
				TextColor3 = T.White,
				TextSize = 13,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
			})

			input.FocusLost:Connect(function(enter)
				if enter then
					Callback(input.Text)
					if Disappear then input.Text = "" end
					SaveIfEnabled()
				end
			end)

			row.MouseButton1Click:Connect(function()
				input:CaptureFocus()
			end)

			local Textbox = {
				Value = "",
				Type = "Textbox",
				Save = C.Save or false,
				Set = function(v) input.Text = v end,
			}
			Track(input:GetPropertyChangedSignal("Text"):Connect(function() Textbox.Value = input.Text end))
			if C.Flag then FrutyLib.Flags[C.Flag] = Textbox end
			Register(row, Name)
			return Textbox
		end

		function ElementFunction:AddLabel(Text)
			local row = Create("TextLabel", {
				Parent = container,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = Text or "",
				TextColor3 = T.Muted,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Register(row, Text or "")
			return {Set = function(v) row.Text = v end}
		end

		function ElementFunction:AddParagraph(Text, Content)
			Text = Text or "Text"
			Content = Content or "Content"

			local row = Create("Frame", {
				Parent = container,
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundColor3 = T.Card,
				BorderSizePixel = 0,
			}, {Corner(6)})
			MakeLabel(Text, 14, T.White, true, {Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16)}).Parent = row
			local body = MakeLabel(Content, 13, T.Muted, false, {
				Position = UDim2.new(0, 12, 0, 27),
				Size = UDim2.new(1, -24, 0, 16),
				TextWrapped = true,
			})
			body.Parent = row

			Track(body:GetPropertyChangedSignal("Text"):Connect(function()
				row.Size = UDim2.new(1, 0, 0, body.TextBounds.Y + 36)
			end))
			task.defer(function()
				row.Size = UDim2.new(1, 0, 0, body.TextBounds.Y + 36)
			end)

			Register(row, Text)
			return {Set = function(v) body.Text = v end}
		end

		function ElementFunction:AddColorPicker(C)
			C = C or {}
			local Name = C.Name or "Color"
			local Callback = C.Callback or function() end
			local CP = {Value = C.Default or Color3.fromRGB(217, 56, 62), Type = "ColorPicker", Save = C.Save or false}

			local row = NewRow(36)
			row.ClipsDescendants = true
			RowLabel(row, Name)
			local swatch = Create("Frame", {
				Parent = row,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 24, 0, 24),
				BackgroundColor3 = CP.Value,
				BorderSizePixel = 0,
			}, {Corner(6), Stroke(T.Border, 1)})

			local R, G, B = math.floor(CP.Value.R * 255 + 0.5), math.floor(CP.Value.G * 255 + 0.5), math.floor(CP.Value.B * 255 + 0.5)
			local Open = false
			local sliders = {}
			local syncing = false

			local function MakeMini(y, letter, init, cb)
				local l = MakeLabel(letter, 12, T.Muted, false, {Position = UDim2.new(0, 14, 0, y), Size = UDim2.new(0, 18, 0, 16)})
				l.Parent = row
				local bar = Create("Frame", {
					Parent = row,
					Position = UDim2.new(0, 36, 0, y + 6),
					Size = UDim2.new(1, -120, 0, 4),
					BackgroundColor3 = T.Off,
					BorderSizePixel = 0,
					Active = true,
				}, {Corner(2)})
				local fill = Create("Frame", {Parent = bar, Size = UDim2.fromScale(init / 255, 1), BackgroundColor3 = T.Accent2, BorderSizePixel = 0}, {Corner(2)})
				local val = MakeLabel(tostring(init), 11, T.Muted, false, {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -12, 0, y),
					Size = UDim2.new(0, 40, 0, 16),
					TextXAlignment = Enum.TextXAlignment.Right,
				})
				val.Parent = row
				local dragging = false
				local function setFrom(x)
					local pct = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
					local v = math.floor(pct * 255 + 0.5)
					fill.Size = UDim2.fromScale(v / 255, 1)
					val.Text = tostring(v)
					cb(v)
				end
				Track(bar.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFrom(Input.Position.X) end
				end))
				Track(UserInputService.InputChanged:Connect(function(Input)
					if dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then setFrom(Input.Position.X) end
				end))
				Track(UserInputService.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end))
				return {Set = function(v) fill.Size = UDim2.fromScale(v / 255, 1); val.Text = tostring(v) end}
			end

			local function ApplyColor()
				CP.Value = Color3.fromRGB(R, G, B)
				Tween(swatch, {BackgroundColor3 = CP.Value}, 0.1)
				Callback(CP.Value)
			end

			sliders[1] = MakeMini(44, "R", R, function(v) R = v; ApplyColor() end)
			sliders[2] = MakeMini(74, "G", G, function(v) G = v; ApplyColor() end)
			sliders[3] = MakeMini(104, "B", B, function(v) B = v; ApplyColor() end)

			function CP:Set(color)
				syncing = true
				R, G, B = math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)
				sliders[1].Set(R); sliders[2].Set(G); sliders[3].Set(B)
				CP.Value = color
				Tween(swatch, {BackgroundColor3 = color}, 0.1)
				syncing = false
			end

			row.MouseButton1Click:Connect(function()
				Open = not Open
				row.Size = Open and UDim2.new(1, 0, 0, 134) or UDim2.new(1, 0, 0, 36)
			end)

			if C.Flag then FrutyLib.Flags[C.Flag] = CP end
			Register(row, Name)
			return CP
		end

		ElementFunction.AddKeybind = ElementFunction.AddBind

		return ElementFunction
	end

	MainWindow.Visible = true
	Tween(MainWindow, {Size = FullSize}, 0.35)

	Window.Notify = function(...) return FrutyLib:MakeNotification(...) end
	Window.Destroy = function() FrutyLib:Destroy() end
	return Window
end

function FrutyLib:Init()
	if not FrutyLib.SaveCfgEnabled then return end
	pcall(function()
		local path = FrutyLib.Folder .. "/" .. game.GameId .. ".txt"
		if isfile and isfile(path) then
			local data = HttpService:JSONDecode(readfile(path))
			for k, v in pairs(data) do
				local f = FrutyLib.Flags[k]
				if f then
					task.spawn(function()
						if f.Type == "ColorPicker" then
							f:Set(Color3.fromRGB(v.R, v.G, v.B))
						else
							f:Set(v)
						end
					end)
				end
			end
		end
	end)
end

function FrutyLib:Destroy()
	FrutyLib.Destroyed = true
	for _, c in ipairs(FrutyLib.Connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(FrutyLib.Connections)
	if FrutyLib.Gui then FrutyLib.Gui:Destroy() end
end

function FrutyLib:IsRunning()
	return not FrutyLib.Destroyed and FrutyLib.Gui and FrutyLib.Gui.Parent ~= nil
end

return FrutyLib
