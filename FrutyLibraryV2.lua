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
	Gui = nil,
	WindowFrame = nil,
	NotifHolder = nil,
	Minimized = false,
	FullSize = UDim2.fromOffset(720, 460),
	MinSize = UDim2.fromOffset(720, 52),
	Settings = {
		Animations = true,
		Accent = Color3.fromRGB(217, 56, 62),
		SearchVisible = true,
	},
	_loadedNotified = false,
}

local Theme = {
	Background = Color3.fromRGB(15, 16, 19),
	Rail = Color3.fromRGB(12, 13, 16),
	Card = Color3.fromRGB(21, 22, 27),
	Hover = Color3.fromRGB(28, 30, 36),
	Border = Color3.fromRGB(44, 46, 54),
	Divider = Color3.fromRGB(34, 36, 44),
	Text = Color3.fromRGB(210, 212, 220),
	Muted = Color3.fromRGB(146, 149, 160),
	White = Color3.fromRGB(245, 246, 248),
	Off = Color3.fromRGB(56, 58, 66),
	Search = Color3.fromRGB(23, 24, 30),
}

local function Track(connection)
	table.insert(FrutyLib.Connections, connection)
	return connection
end

local function DisconnectAll()
	for _, c in ipairs(FrutyLib.Connections) do
		pcall(function() c:Disconnect() end)
	end
	FrutyLib.Connections = {}
end

local function TweenObj(obj, props, dur, style, dir)
	if not FrutyLib.Settings.Animations then
		for k, v in pairs(props) do obj[k] = v end
		return {Cancel = function() end}
	end
	local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Create(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, ch in ipairs(children or {}) do ch.Parent = obj end
	return obj
end

local function Corner(r) return Create("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end

local function Stroke(target, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = target,
	})
end

local function MakeLabel(text, size, color, bold, props)
	local l = Create("TextLabel", {
		Text = text or "",
		TextSize = size or 14,
		TextColor3 = color or Theme.Text,
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end

local IconRegistry = setmetatable({}, {__mode = "k"})
local function RegisterIconPart(holder, object, kind)
	IconRegistry[holder] = IconRegistry[holder] or {}
	table.insert(IconRegistry[holder], {Object = object, Kind = kind})
end
local function SetIconColor(holder, color, duration)
	local parts = IconRegistry[holder]
	if not parts then
		if holder and holder:IsA("ImageLabel") then TweenObj(holder, {ImageColor3 = color}, duration or 0.18) end
		return
	end
	for _, p in ipairs(parts) do
		local o = p.Object
		if o and o.Parent then
			if p.Kind == "stroke" then TweenObj(o, {Color = color}, duration or 0.18)
			elseif p.Kind == "image" then TweenObj(o, {ImageColor3 = color}, duration or 0.18)
			else TweenObj(o, {BackgroundColor3 = color}, duration or 0.18) end
		end
	end
end

local function MakeIcon(name, iconSize, iconColor)
	local size = iconSize or 16
	local color = iconColor or Theme.Muted
	local holder = Create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0})
	local thickness = math.max(2, math.floor(size / 8 + 0.5))
	local c = size / 2
	local function Bar(w, h, rot, ox, oy)
		local b = Create("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,c+(ox or 0),0,c+(oy or 0)), Size = UDim2.fromOffset(w,h), Rotation = rot or 0, BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder})
		Corner(math.max(1, math.floor(h/2))).Parent = b
		RegisterIconPart(holder, b, "fill")
	end
	local function Ring(d, ox, oy)
		local r = Create("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,c+(ox or 0),0,c+(oy or 0)), Size = UDim2.fromOffset(d,d), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = holder})
		Corner(math.floor(d/2)).Parent = r
		RegisterIconPart(holder, Stroke(r, color, thickness, 0), "stroke")
	end
	local function Dot(d, ox, oy)
		local dt = Create("Frame", {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,c+(ox or 0),0,c+(oy or 0)), Size = UDim2.fromOffset(d,d), BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder})
		Corner(math.floor(d/2)).Parent = dt
		RegisterIconPart(holder, dt, "fill")
	end

	if name == "crosshair" then
		Ring(size*0.62); Bar(thickness,size*0.24,0,0,-size*0.29); Bar(thickness,size*0.24,0,0,size*0.29); Bar(size*0.24,thickness,0,-size*0.29,0); Bar(size*0.24,thickness,0,size*0.29,0); Dot(size*0.16)
	elseif name == "eye" then
		Ring(size*0.72); Bar(size*0.8,thickness,0,0,-size*0.28); Bar(size*0.8,thickness,0,0,size*0.28); Dot(size*0.28)
	elseif name == "skull" then
		Ring(size*0.72,0,-size*0.04); Dot(size*0.14,-size*0.14,-size*0.08); Dot(size*0.14,size*0.14,-size*0.08); Bar(size*0.34,thickness,0,0,size*0.19); Bar(thickness,size*0.14,0,-size*0.08,size*0.27); Bar(thickness,size*0.14,0,0,size*0.27); Bar(thickness,size*0.14,0,size*0.08,size*0.27)
	elseif name == "search" then
		Ring(size*0.56,-size*0.08,-size*0.08); Bar(size*0.38,thickness,45,size*0.18,size*0.18)
	elseif name == "settings" then
		Ring(size*0.52); Dot(size*0.2); Bar(thickness,size*0.18,0,0,-size*0.34); Bar(thickness,size*0.18,0,0,size*0.34); Bar(size*0.18,thickness,0,-size*0.34,0); Bar(size*0.18,thickness,0,size*0.34,0)
	elseif name == "chevron-down" then
		Bar(size*0.42,thickness,45,-size*0.12,0); Bar(size*0.42,thickness,-45,size*0.12,0)
	elseif name == "chevron-right" then
		Bar(size*0.42,thickness,45,0,-size*0.12); Bar(size*0.42,thickness,-45,0,size*0.12)
	elseif name == "close" or name == "x" then
		Bar(size*0.72,thickness,45); Bar(size*0.72,thickness,-45)
	elseif name == "minus" then
		Bar(size*0.64,thickness)
	elseif name == "plus" then
		Bar(size*0.64,thickness); Bar(size*0.64,thickness,90)
	else
		Dot(size*0.28)
	end
	return holder
end

local function ResolveIcon(icon, iconSize, iconColor)
	local color = iconColor or Theme.Muted
	if type(icon) == "string" and icon:sub(1, 12) == "rbxassetid://" then
		local img = Create("ImageLabel", {Size = UDim2.fromOffset(iconSize, iconSize), BackgroundTransparency = 1, BorderSizePixel = 0, Image = icon, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit})
		RegisterIconPart(img, img, "image")
		return img
	end
	return MakeIcon(icon or "circle", iconSize, color)
end

function FrutyLib:SaveConfig()
	if not self.SaveCfgEnabled or not self.Folder then return end
	pcall(function()
		local data = {}
		for flag, entry in pairs(self.Flags) do
			if entry and entry.Save then
				if entry.Type == "ColorPicker" and typeof(entry.Value) == "Color3" then
					data[flag] = {__type="Color3", R=math.floor(entry.Value.R*255+0.5), G=math.floor(entry.Value.G*255+0.5), B=math.floor(entry.Value.B*255+0.5)}
				elseif entry.Type == "Bind" then
					local k = entry.Value
					data[flag] = {__type="Bind", Key = typeof(k)=="EnumItem" and k.Name or tostring(k)}
				else
					data[flag] = entry.Value
				end
			end
		end
		if writefile then writefile(self.Folder .. "/" .. game.GameId .. ".json", HttpService:JSONEncode(data)) end
	end)
end

function FrutyLib:LoadConfig()
	if not self.SaveCfgEnabled or not self.Folder then return end
	pcall(function()
		local path = self.Folder .. "/" .. game.GameId .. ".json"
		if isfile and isfile(path) and readfile then
			local data = HttpService:JSONDecode(readfile(path))
			for flag, value in pairs(data) do
				local entry = self.Flags[flag]
				if entry and entry.Save and entry.Set then
					if type(value) == "table" and value.__type == "Color3" then
						entry:Set(Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255))
					elseif type(value) == "table" and value.__type == "Bind" then
						local kn = value.Key
						if kn and Enum.KeyCode[kn] then entry:Set(Enum.KeyCode[kn]) end
					else
						entry:Set(value)
					end
				end
			end
		end
	end)
end

function FrutyLib:MakeNotification(config)
	config = config or {}
	task.spawn(function()
		if self.Destroyed or not self.Gui or not self.NotifHolder then return end
		local title = config.Name or "Notification"
		local content = config.Content or ""
		local duration = config.Time or 4
		local holder = Create("Frame", {Parent = self.NotifHolder, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Position = UDim2.new(0,320,0,0)})
		local card = Create("Frame", {Parent = holder, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Card, BorderSizePixel = 0}, {Corner(10)})
		Stroke(card, Theme.Border, 1, 0)
		Create("Frame", {Parent = card, Size = UDim2.new(0,3,1,0), BackgroundColor3 = self.Settings.Accent, BorderSizePixel = 0}, {Corner(2)})
		MakeLabel(title, 14, Theme.White, true, {Parent = card, Position = UDim2.new(0,14,0,10), Size = UDim2.new(1,-28,0,16)})
		MakeLabel(content, 13, Theme.Muted, false, {Parent = card, Position = UDim2.new(0,14,0,30), Size = UDim2.new(1,-28,0,0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true})
		Create("Frame", {Parent = card, Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,1,-10), BackgroundTransparency = 1})
		TweenObj(holder, {Position = UDim2.new(0,0,0,0)}, 0.35)
		task.wait(duration)
		if self.Destroyed or not holder.Parent then return end
		TweenObj(holder, {Position = UDim2.new(0,330,0,0)}, 0.28)
		task.wait(0.3)
		if holder and holder.Parent then holder:Destroy() end
	end)
end

function FrutyLib:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	DisconnectAll()
	if self.Gui then pcall(function() self.Gui:Destroy() end) self.Gui = nil end
	self.Flags = {}
	self.ActiveRows = nil
	self.WindowFrame = nil
	self.NotifHolder = nil
end

function FrutyLib:Init()
	if self._loadedNotified then return end
	self._loadedNotified = true
	self:LoadConfig()
	self:MakeNotification({Name = "Fruty Private", Content = "Interface loaded", Time = 3})
end

function FrutyLib:MakeWindow(config)
	config = config or {}
	if self.Gui then pcall(function() self.Gui:Destroy() end) end
	self.Destroyed = false
	self.Flags = {}
	self.Connections = {}
	self.ActiveRows = nil
	self._loadedNotified = false
	self.Minimized = false

	local windowName = config.Name or "Fruty Private"
	self.Folder = config.ConfigFolder or windowName
	self.SaveCfgEnabled = config.SaveConfig == true
	if self.SaveCfgEnabled and isfolder and makefolder then
		pcall(function() if not isfolder(self.Folder) then makefolder(self.Folder) end end)
	end

	local screenGui = Create("ScreenGui", {
		Name = "FrutyPrivate_" .. tostring(math.random(100000,999999)),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999999,
	})
	self.Gui = screenGui
	if syn and syn.protect_gui then pcall(syn.protect_gui, screenGui) end
	local okp = pcall(function() screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not okp or not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local notifHolder = Create("Frame", {
		Parent = screenGui, AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-16,1,-16),
		Size = UDim2.new(0,300,0,500), BackgroundTransparency = 1,
	}, {Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,8)})})
	self.NotifHolder = notifHolder

	local mainWindow = Create("Frame", {
		Parent = screenGui, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
		Size = self.FullSize, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true,
	}, {Corner(12)})
	Stroke(mainWindow, Theme.Border, 1, 0)
	self.WindowFrame = mainWindow

	local topBar = Create("Frame", {Parent = mainWindow, Size = UDim2.new(1,0,0,52), BackgroundColor3 = Theme.Rail, BorderSizePixel = 0, ClipsDescendants = true}, {Corner(12)})
	Create("Frame", {Parent = topBar, Position = UDim2.new(0,0,1,-12), Size = UDim2.new(1,0,0,12), BackgroundColor3 = Theme.Rail, BorderSizePixel = 0})
	Create("Frame", {Parent = topBar, Position = UDim2.new(0,0,1,-1), Size = UDim2.new(1,0,0,1), BackgroundColor3 = Theme.Divider, BorderSizePixel = 0})

	local logo = Create("Frame", {Parent = topBar, AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,14,0.5,0), Size = UDim2.fromOffset(28,28), BackgroundColor3 = self.Settings.Accent, BorderSizePixel = 0}, {Corner(8)})
	MakeLabel("F", 15, Theme.White, true, {Parent = logo, Size = UDim2.fromScale(1,1), TextXAlignment = Enum.TextXAlignment.Center})
	MakeLabel(windowName, 16, Theme.White, true, {Parent = topBar, Position = UDim2.new(0,52,0,0), Size = UDim2.new(1,-210,1,0)})

	local dragPoint = Create("TextButton", {Parent = topBar, Size = UDim2.new(1,-140,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false})

	local function MakeTopButton(iconName, rightOffset)
		local btn = Create("TextButton", {Parent = topBar, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,rightOffset,0.5,0), Size = UDim2.fromOffset(30,30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, {Corner(8)})
		Stroke(btn, Theme.Border, 1, 0)
		local icon = MakeIcon(iconName, 14, Theme.Muted)
		icon.AnchorPoint = Vector2.new(0.5,0.5); icon.Position = UDim2.fromScale(0.5,0.5); icon.Parent = btn
		local alt
		if iconName == "minus" then
			alt = MakeIcon("plus", 14, Theme.Muted)
			alt.AnchorPoint = Vector2.new(0.5,0.5); alt.Position = UDim2.fromScale(0.5,0.5); alt.Visible = false; alt.Parent = btn
		end
		btn.MouseEnter:Connect(function() TweenObj(btn,{BackgroundColor3=Theme.Hover},0.16); SetIconColor(icon,Theme.White,0.16); if alt then SetIconColor(alt,Theme.White,0.16) end end)
		btn.MouseLeave:Connect(function() TweenObj(btn,{BackgroundColor3=Theme.Card},0.16); SetIconColor(icon,Theme.Muted,0.16); if alt then SetIconColor(alt,Theme.Muted,0.16) end end)
		return btn, icon, alt
	end

	local closeButton = MakeTopButton("close", -12)
	local minimizeButton, minimizeIcon, restoreIcon = MakeTopButton("minus", -48)
	local settingsButton = MakeTopButton("settings", -84)

	local body = Create("Frame", {Parent = mainWindow, Position = UDim2.new(0,0,0,52), Size = UDim2.new(1,0,1,-52), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true})
	local sidebar = Create("Frame", {Parent = body, Size = UDim2.new(0,196,1,0), BackgroundColor3 = Theme.Rail, BorderSizePixel = 0})
	Create("Frame", {Parent = sidebar, Position = UDim2.new(1,-1,0,0), Size = UDim2.new(0,1,1,0), BackgroundColor3 = Theme.Divider, BorderSizePixel = 0})
	local content = Create("Frame", {Parent = body, Position = UDim2.new(0,196,0,0), Size = UDim2.new(1,-196,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true})

	local tabTitle = MakeLabel("", 18, Theme.White, true, {Parent = content, Position = UDim2.new(0,16,0,0), Size = UDim2.new(1,-220,0,48)})

	local searchFrame = Create("Frame", {Parent = content, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-16,0,24), Size = UDim2.new(0,180,0,30), BackgroundColor3 = Theme.Search, BorderSizePixel = 0}, {Corner(8)})
	local searchStroke = Stroke(searchFrame, Theme.Border, 1, 0)
	local sIcon = MakeIcon("search", 13, Theme.Muted); sIcon.AnchorPoint=Vector2.new(0,0.5); sIcon.Position=UDim2.new(0,10,0.5,0); sIcon.Parent=searchFrame
	local searchBox = Create("TextBox", {Parent = searchFrame, Position = UDim2.new(0,30,0,0), Size = UDim2.new(1,-40,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = "Search", PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.White, TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
	searchBox.Focused:Connect(function() TweenObj(searchStroke,{Color=FrutyLib.Settings.Accent},0.16) end)
	searchBox.FocusLost:Connect(function() TweenObj(searchStroke,{Color=Theme.Border},0.16) end)

	local tabHolder = Create("ScrollingFrame", {Parent = sidebar, Position = UDim2.new(0,0,0,12), Size = UDim2.new(1,0,1,-78), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Divider, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y}, {
		Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4)}),
		Create("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,4)}),
	})

	local playerCard = Create("Frame", {Parent = sidebar, AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,10,1,-10), Size = UDim2.new(1,-20,0,46), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}, {Corner(10)})
	Stroke(playerCard, Theme.Border, 1, 0)
	Create("ImageLabel", {Parent = playerCard, AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,8,0.5,0), Size = UDim2.fromOffset(30,30), BackgroundTransparency = 1, Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"}, {Corner(15)})
	MakeLabel(LocalPlayer.DisplayName, 13, Theme.White, true, {Parent = playerCard, Position = UDim2.new(0,44,0,7), Size = UDim2.new(1,-52,0,16), TextTruncate = Enum.TextTruncate.AtEnd})
	MakeLabel("@"..LocalPlayer.Name, 11, Theme.Muted, false, {Parent = playerCard, Position = UDim2.new(0,44,0,24), Size = UDim2.new(1,-52,0,14), TextTruncate = Enum.TextTruncate.AtEnd})

	local tabs = {}
	local activeTab = nil
	local firstTab = true
	local searchVisible = true

	local function ApplySearch(query)
		local rows = FrutyLib.ActiveRows
		if not rows then return end
		local q = string.lower(query or "")
		for _, row in ipairs(rows) do
			row.Frame.Visible = (q == "") or (string.find(row.Text, q, 1, true) ~= nil)
		end
	end
	Track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		ApplySearch(searchBox.Text)
	end))

	local function SelectTab(tab)
		for _, t in ipairs(tabs) do
			t.Bar.Visible = false
			TweenObj(t.Button, {BackgroundColor3 = Theme.Rail}, 0.18)
			SetIconColor(t.Icon, Theme.Muted, 0.18)
			TweenObj(t.Title, {TextColor3 = Theme.Muted}, 0.18)
			t.Container.Visible = false
		end
		tab.Bar.Visible = true
		tab.Bar.BackgroundColor3 = FrutyLib.Settings.Accent
		TweenObj(tab.Button, {BackgroundColor3 = Theme.Hover}, 0.18)
		SetIconColor(tab.Icon, FrutyLib.Settings.Accent, 0.18)
		TweenObj(tab.Title, {TextColor3 = Theme.White}, 0.18)
		tab.Container.Visible = true
		activeTab = tab
		tabTitle.Text = tab.Name
		FrutyLib.ActiveRows = tab.Rows
		ApplySearch(searchBox.Text)
	end

	local function RegisterRow(tab, frame, text)
		table.insert(tab.Rows, {Frame = frame, Text = string.lower(text or "")})
	end

	local function MakeRow(container, height)
		return Create("Frame", {Parent = container, Size = UDim2.new(1,0,0,height or 36), BackgroundTransparency = 1, BorderSizePixel = 0})
	end

	local function MakeLabelRow(tab, text)
		local row = MakeRow(tab.Container, 28)
		local lbl = MakeLabel(text or "", 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,5), Size = UDim2.new(1,-8,0,18)})
		RegisterRow(tab, row, text)
		return {Set = function(_, v) lbl.Text = v or ""; for _,r in ipairs(tab.Rows) do if r.Frame==row then r.Text=string.lower(v or "") end end; ApplySearch(searchBox.Text) end}
	end

	local function MakeParagraphRow(tab, text, desc)
		local row = MakeRow(tab.Container, 58)
		MakeLabel(text or "Paragraph", 14, Theme.White, true, {Parent = row, Position = UDim2.new(0,4,0,4), Size = UDim2.new(1,-8,0,16)})
		local body = MakeLabel(desc or "", 13, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,26), Size = UDim2.new(1,-8,0,20), TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y})
		RegisterRow(tab, row, (text or "").." "..(desc or ""))
		return {Set = function(_, v) body.Text = v or "" end}
	end

	local function MakeButtonRow(tab, cfg)
		cfg = cfg or {}
		local name = cfg.Name or "Button"
		local callback = cfg.Callback or function() end
		local row = MakeRow(tab.Container, 38)
		RegisterRow(tab, row, name)
		MakeLabel(name, 14, Theme.White, false, {Parent = row, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-120,1,0)})
		local btn = Create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.new(0,90,0,28), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = "Run", TextColor3 = Theme.White, TextSize = 13, Font = Enum.Font.GothamMedium, AutoButtonColor = false}, {Corner(8)})
		Stroke(btn, Theme.Border, 1, 0)
		btn.MouseEnter:Connect(function() TweenObj(btn,{BackgroundColor3=Theme.Hover},0.14) end)
		btn.MouseLeave:Connect(function() TweenObj(btn,{BackgroundColor3=Theme.Card},0.14) end)
		btn.MouseButton1Click:Connect(function()
			TweenObj(btn,{BackgroundColor3=FrutyLib.Settings.Accent},0.08)
			task.delay(0.12, function() if btn.Parent then TweenObj(btn,{BackgroundColor3=Theme.Card},0.18) end end)
			pcall(callback)
		end)
		return {Set = function(_, v) btn.Text = tostring(v or "Run") end}
	end

	local function MakeToggleRow(tab, cfg)
		cfg = cfg or {}
		local name = cfg.Name or "Toggle"
		local callback = cfg.Callback or function() end
		local flag = cfg.Flag or name
		local save = cfg.Save; if save == nil then save = true end
		local value = cfg.Default == true
		local row = MakeRow(tab.Container, 38)
		RegisterRow(tab, row, name)
		MakeLabel(name, 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-80,1,0)})
		local toggle = Create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.fromOffset(44,24), BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, {Corner(12)})
		Stroke(toggle, Theme.Border, 1, 0)
		local knob = Create("Frame", {Parent = toggle, AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,3,0.5,0), Size = UDim2.fromOffset(18,18), BackgroundColor3 = Theme.White, BorderSizePixel = 0}, {Corner(9)})
		local object
		local function Apply(state, silent)
			value = state == true
			TweenObj(toggle, {BackgroundColor3 = value and FrutyLib.Settings.Accent or Theme.Off}, 0.18)
			TweenObj(knob, {Position = value and UDim2.new(1,-21,0.5,0) or UDim2.new(0,3,0.5,0)}, 0.18)
			if object then object.Value = value end
			if not silent then
				pcall(callback, value)
				if save then FrutyLib:SaveConfig() end
			end
		end
		toggle.MouseButton1Click:Connect(function() Apply(not value, false) end)
		object = {Type="Toggle", Value=value, Save=save, Callback=callback, Set=function(_,v) Apply(v,true) end}
		if flag then FrutyLib.Flags[flag] = object end
		Apply(value, true)
		return object
	end

	local function MakeSliderRow(tab, cfg)
		cfg = cfg or {}
		local name = cfg.Name or "Slider"
		local min = tonumber(cfg.Min) or 0
		local max = tonumber(cfg.Max) or 100
		local increment = tonumber(cfg.Increment) or 1
		local default = tonumber(cfg.Default) or min
		local callback = cfg.Callback or function() end
		local flag = cfg.Flag or name
		local save = cfg.Save; if save == nil then save = true end
		local value = math.clamp(default, min, max)
		local row = MakeRow(tab.Container, 54)
		RegisterRow(tab, row, name)

		MakeLabel(name, 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,4), Size = UDim2.new(1,-90,0,16)})
		local valueLabel = MakeLabel(tostring(value), 13, Theme.Muted, false, {Parent = row, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-4,0,4), Size = UDim2.new(0,70,0,16), TextXAlignment = Enum.TextXAlignment.Right})
		local barBg = Create("Frame", {Parent = row, Position = UDim2.new(0,4,0,34), Size = UDim2.new(1,-8,0,6), BackgroundColor3 = Theme.Off, BorderSizePixel = 0}, {Corner(3)})
		local fill = Create("Frame", {Parent = barBg, Size = UDim2.fromScale(0,1), BackgroundColor3 = FrutyLib.Settings.Accent, BorderSizePixel = 0}, {Corner(3)})

		local object
		local function SetValue(v, silent)
			v = math.clamp(tonumber(v) or min, min, max)
			if increment > 0 then
				v = math.floor(v / increment + 0.5) * increment
				v = math.clamp(v, min, max)
			end
			value = v
			local pct = (max == min) and 0 or ((value - min) / (max - min))
			TweenObj(fill, {Size = UDim2.fromScale(pct, 1)}, 0.1)
			valueLabel.Text = tostring(value)
			if object then object.Value = value end
			if not silent then
				pcall(callback, value)
				if save then FrutyLib:SaveConfig() end
			end
		end

		local draggingSlider = false
		local function Update(input)
			local x = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
			SetValue(min + (max - min) * x, false)
		end
		barBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true; Update(input) end
		end)
		Track(UserInputService.InputChanged:Connect(function(input)
			if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
		end))

		object = {Type="Slider", Value=value, Save=save, Callback=callback, Set=function(_,v) SetValue(v,true) end}
		if flag then FrutyLib.Flags[flag] = object end
		SetValue(value, true)
		return object
	end

	local function MakeDropdownRow(tab, cfg)
		cfg = cfg or {}
		local name = cfg.Name or "Dropdown"
		local options = cfg.Options or {}
		local default = cfg.Default
		local callback = cfg.Callback or function() end
		local flag = cfg.Flag or name
		local save = cfg.Save; if save == nil then save = true end

		local selected = default or options[1] or ""
		local open = false
		local row = MakeRow(tab.Container, 38)
		RegisterRow(tab, row, name)

		local header = Create("TextButton", {Parent = row, Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1, Text = "", AutoButtonColor = false})
		MakeLabel(name, 14, Theme.Muted, false, {Parent = header, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-180,1,0)})
		local valueBox = Create("Frame", {Parent = header, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.new(0,150,0,28), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}, {Corner(8)})
		Stroke(valueBox, Theme.Border, 1, 0)
		local valueLabel = MakeLabel(tostring(selected), 13, Theme.Muted, false, {Parent = valueBox, Position = UDim2.new(0,10,0,0), Size = UDim2.new(1,-34,1,0), TextTruncate = Enum.TextTruncate.AtEnd})
		local arrow = MakeIcon("chevron-down", 14, Theme.Muted)
		arrow.AnchorPoint = Vector2.new(1,0.5); arrow.Position = UDim2.new(1,-8,0.5,0); arrow.Parent = valueBox

		local listHolder = Create("Frame", {Parent = row, Position = UDim2.new(0,4,0,42), Size = UDim2.new(1,-8,0,0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, {Corner(8)})
		Stroke(listHolder, Theme.Border, 1, 0)
		local listLayout = Create("UIListLayout", {Parent = listHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2)})
		Create("UIPadding", {Parent = listHolder, PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4)})

		local optionButtons = {}
		local object

		local function Refresh()
			for _, b in ipairs(optionButtons) do b:Destroy() end
			optionButtons = {}
			for _, opt in ipairs(options) do
				local optBtn = Create("TextButton", {Parent = listHolder, Size = UDim2.new(1,0,0,26), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = tostring(opt), TextColor3 = Theme.Muted, TextSize = 13, Font = Enum.Font.GothamMedium, AutoButtonColor = false}, {Corner(6)})
				optBtn.MouseEnter:Connect(function() if selected ~= opt then TweenObj(optBtn,{BackgroundColor3=Theme.Hover,TextColor3=Theme.White},0.12) end end)
				optBtn.MouseLeave:Connect(function() if selected ~= opt then TweenObj(optBtn,{BackgroundColor3=Theme.Card,TextColor3=Theme.Muted},0.12) end end)
				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					valueLabel.Text = tostring(opt)
					for _, b in ipairs(optionButtons) do
						local isSel = b.Text == tostring(selected)
						b.BackgroundColor3 = isSel and Theme.Hover or Theme.Card
						b.TextColor3 = isSel and Theme.White or Theme.Muted
					end
					if object then object.Value = selected end
					pcall(callback, selected)
					if save then FrutyLib:SaveConfig() end
					open = false
					listHolder.Visible = false
					TweenObj(row, {Size = UDim2.new(1,0,0,38)}, 0.18)
				end)
				table.insert(optionButtons, optBtn)
			end
			for _, b in ipairs(optionButtons) do
				local isSel = b.Text == tostring(selected)
				b.BackgroundColor3 = isSel and Theme.Hover or Theme.Card
				b.TextColor3 = isSel and Theme.White or Theme.Muted
			end
		end

		local function SetOpen(state)
			open = state
			if open then
				Refresh()
				listHolder.Visible = true
				local h = math.min(#options, 6) * 28 + 8
				listHolder.Size = UDim2.new(1,-8,0,h)
				TweenObj(row, {Size = UDim2.new(1,0,0,42+h)}, 0.18)
			else
				TweenObj(row, {Size = UDim2.new(1,0,0,38)}, 0.18)
				task.delay(0.18, function() if not open and listHolder.Parent then listHolder.Visible = false end end)
			end
		end

		header.MouseButton1Click:Connect(function() SetOpen(not open) end)
		header.MouseEnter:Connect(function() TweenObj(valueBox,{BackgroundColor3=Theme.Hover},0.12) end)
		header.MouseLeave:Connect(function() TweenObj(valueBox,{BackgroundColor3=Theme.Card},0.12) end)

		object = {
			Type = "Dropdown",
			Value = selected,
			Save = save,
			Callback = callback,
			Set = function(_, v)
				selected = v
				valueLabel.Text = tostring(v)
				if object then object.Value = v end
				Refresh()
			end,
			Refresh = function(_, newOptions)
				options = newOptions or options
				if not table.find(options, selected) then selected = options[1] or "" end
				valueLabel.Text = tostring(selected)
				Refresh()
			end,
		}
		if flag then FrutyLib.Flags[flag] = object end
		Refresh()
		return object
	end

	local function MakeBindRow(tab, cfg)
		cfg = cfg or {}
		local name = cfg.Name or "Bind"
		local default = cfg.Default or Enum.KeyCode.RightShift
		local callback = cfg.Callback or function() end
		local flag = cfg.Flag or name
		local save = cfg.Save; if save == nil then save = true end
		local value = default
		local listening = false

		local row = MakeRow(tab.Container, 38)
		RegisterRow(tab, row, name)
		MakeLabel(name, 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-130,1,0)})
		local bindBtn = Create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.new(0,110,0,28), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = typeof(value)=="EnumItem" and value.Name or tostring(value), TextColor3 = Theme.White, TextSize = 13, Font = Enum.Font.GothamMedium, AutoButtonColor = false}, {Corner(8)})
		Stroke(bindBtn, Theme.Border, 1, 0)

		local object
		local function SetBind(k, silent)
			value = k
			bindBtn.Text = typeof(k)=="EnumItem" and k.Name or tostring(k)
			if object then object.Value = value end
			if not silent then
				pcall(callback, value)
				if save then FrutyLib:SaveConfig() end
			end
		end

		bindBtn.MouseButton1Click:Connect(function()
			listening = true
			bindBtn.Text = "..."
		end)
		Track(UserInputService.InputBegan:Connect(function(input, gpe)
			if listening and input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				SetBind(input.KeyCode, false)
			elseif not gpe and not listening and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == value then
				pcall(callback, value)
			end
		end))

		object = {Type="Bind", Value=value, Save=save, Callback=callback, Set=function(_,v) SetBind(v,true) end}
		if flag then FrutyLib.Flags[flag] = object end
		SetBind(value, true)
		return object
	end


	local Window = {}

	function Window:MakeTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon or "circle"

		local button = Create("TextButton", {Parent = tabHolder, Size = UDim2.new(1,0,0,34), BackgroundColor3 = Theme.Rail, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, {Corner(8)})
		local bar = Create("Frame", {Parent = button, AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(0,3,0,14), BackgroundColor3 = FrutyLib.Settings.Accent, BorderSizePixel = 0, Visible = false}, {Corner(2)})
		local icon = ResolveIcon(tabIcon, 16, Theme.Muted); icon.AnchorPoint = Vector2.new(0,0.5); icon.Position = UDim2.new(0,10,0.5,0); icon.Parent = button
		local title = MakeLabel(tabName, 14, Theme.Muted, false, {Parent = button, Position = UDim2.new(0,34,0,0), Size = UDim2.new(1,-40,1,0), TextTruncate = Enum.TextTruncate.AtEnd})

		local container = Create("ScrollingFrame", {Parent = content, Position = UDim2.new(0,0,0,48), Size = UDim2.new(1,0,1,-48), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Divider, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, {
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)}),
			Create("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12), PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10)}),
		})

		local tab = {Name = tabName, Button = button, Icon = icon, Title = title, Bar = bar, Container = container, Rows = {}}
		table.insert(tabs, tab)

		button.MouseEnter:Connect(function() if activeTab ~= tab then TweenObj(button,{BackgroundColor3=Theme.Hover},0.16) end end)
		button.MouseLeave:Connect(function() if activeTab ~= tab then TweenObj(button,{BackgroundColor3=Theme.Rail},0.16) end end)
		button.MouseButton1Click:Connect(function() SelectTab(tab) end)

		if firstTab then firstTab = false; SelectTab(tab) end

		local Elements = {}
		function Elements:AddLabel(text)
			return MakeLabelRow(tab, text)
		end
		function Elements:AddParagraph(text, desc)
			return MakeParagraphRow(tab, text, desc)
		end
		function Elements:AddButton(cfg)
			return MakeButtonRow(tab, cfg)
		end
		function Elements:AddToggle(cfg)
			return MakeToggleRow(tab, cfg)
		end
		function Elements:AddSlider(cfg)
			return MakeSliderRow(tab, cfg)
		end
		function Elements:AddDropdown(cfg)
			return MakeDropdownRow(tab, cfg)
		end
		function Elements:AddBind(cfg)
			return MakeBindRow(tab, cfg)
		end
		function Elements:AddTextbox(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Textbox"
			local default = cfg.Default or ""
			local callback = cfg.Callback or function() end
			local flag = cfg.Flag or name
			local save = cfg.Save; if save == nil then save = true end
			local row = MakeRow(tab.Container, 38)
			RegisterRow(tab, row, name)
			MakeLabel(name, 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-170,1,0)})
			local box = Create("TextBox", {Parent = row, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.new(0,150,0,28), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = tostring(default), PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.White, TextSize = 13, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false}, {Corner(8)})
			Stroke(box, Theme.Border, 1, 0)
			local obj = {Type="Textbox", Value=default, Save=save, Callback=callback, Set=function(_,v) box.Text=tostring(v or ""); obj.Value=box.Text end}
			box.FocusLost:Connect(function(enter)
				obj.Value = box.Text
				pcall(callback, box.Text, enter)
				if save then FrutyLib:SaveConfig() end
			end)
			if flag then FrutyLib.Flags[flag] = obj end
			return obj
		end
		function Elements:AddColorPicker(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Color"
			local default = cfg.Default or Color3.fromRGB(255,255,255)
			local callback = cfg.Callback or function() end
			local flag = cfg.Flag or name
			local save = cfg.Save; if save == nil then save = true end
			local value = default
			local row = MakeRow(tab.Container, 38)
			RegisterRow(tab, row, name)
			MakeLabel(name, 14, Theme.Muted, false, {Parent = row, Position = UDim2.new(0,4,0,0), Size = UDim2.new(1,-80,1,0)})
			local swatch = Create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0), Size = UDim2.fromOffset(44,24), BackgroundColor3 = value, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, {Corner(6)})
			Stroke(swatch, Theme.Border, 1, 0)
			local colors = {
				Color3.fromRGB(217,56,62), Color3.fromRGB(255,255,255), Color3.fromRGB(88,101,242),
				Color3.fromRGB(87,242,135), Color3.fromRGB(254,231,92), Color3.fromRGB(255,165,0),
			}
			local idx = 1
			for i,c in ipairs(colors) do if c == default then idx = i end end
			local obj
			local function SetColor(c, silent)
				value = c
				swatch.BackgroundColor3 = c
				if obj then obj.Value = c end
				if not silent then pcall(callback, c); if save then FrutyLib:SaveConfig() end end
			end
			swatch.MouseButton1Click:Connect(function()
				idx = idx % #colors + 1
				SetColor(colors[idx], false)
			end)
			obj = {Type="ColorPicker", Value=value, Save=save, Callback=callback, Set=function(_,v) SetColor(v,true) end}
			if flag then FrutyLib.Flags[flag] = obj end
			SetColor(value, true)
			return obj
		end

		return Elements
	end


	local WindowAPI = {}

	function WindowAPI:MakeTab(cfg)
		return Window:MakeTab(cfg)
	end
	function WindowAPI:Init()
		FrutyLib:Init()
	end
	function WindowAPI:Destroy()
		FrutyLib:Destroy()
	end

	-- Minimize
	minimizeButton.MouseButton1Click:Connect(function()
		FrutyLib.Minimized = not FrutyLib.Minimized
		minimizeIcon.Visible = not FrutyLib.Minimized
		restoreIcon.Visible = FrutyLib.Minimized
		if FrutyLib.Minimized then
			TweenObj(mainWindow, {Size = FrutyLib.MinSize}, 0.28)
			task.delay(0.15, function() if FrutyLib.Minimized and body.Parent then body.Visible = false end end)
		else
			body.Visible = true
			TweenObj(mainWindow, {Size = FrutyLib.FullSize}, 0.28)
		end
	end)

	-- Drag
	local dragging, dragStart, startPos
	dragPoint.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainWindow.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	-- Close/hide
	closeButton.MouseButton1Click:Connect(function()
		mainWindow.Visible = false
		FrutyLib:MakeNotification({Name="Interface Hidden", Content="Press RightShift or Insert to reopen", Time=4})
	end)

	local function SetVisible(state)
		mainWindow.Visible = state
	end
	Track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
			mainWindow.Visible = not mainWindow.Visible
		end
	end))

	-- Settings tab
	local settingsTab = Window:MakeTab({Name = "Settings", Icon = "settings"})
	settingsTab:AddParagraph("Interface", "Customize GUI behavior and appearance.")

	settingsTab:AddToggle({
		Name = "Animations",
		Default = FrutyLib.Settings.Animations,
		Flag = "Fruty_Animations",
		Save = false,
		Callback = function(v)
			FrutyLib.Settings.Animations = v
		end
	})

	settingsTab:AddToggle({
		Name = "Show Search",
		Default = true,
		Flag = "Fruty_ShowSearch",
		Save = false,
		Callback = function(v)
			FrutyLib.Settings.SearchVisible = v
			searchFrame.Visible = v
			tabTitle.Size = v and UDim2.new(1,-220,0,48) or UDim2.new(1,-32,0,48)
		end
	})

	settingsTab:AddDropdown({
		Name = "Accent Color",
		Options = {"Red", "Blue", "Green", "Purple", "White"},
		Default = "Red",
		Flag = "Fruty_Accent",
		Save = false,
		Callback = function(opt)
			local map = {
				Red = Color3.fromRGB(217,56,62),
				Blue = Color3.fromRGB(88,101,242),
				Green = Color3.fromRGB(87,242,135),
				Purple = Color3.fromRGB(155,89,182),
				White = Color3.fromRGB(235,235,235),
			}
			FrutyLib.Settings.Accent = map[opt] or map.Red
			logo.BackgroundColor3 = FrutyLib.Settings.Accent
			if activeTab then
				activeTab.Bar.BackgroundColor3 = FrutyLib.Settings.Accent
				SetIconColor(activeTab.Icon, FrutyLib.Settings.Accent, 0.15)
			end
		end
	})

	settingsTab:AddButton({
		Name = "Unhook GUI",
		Callback = function()
			FrutyLib:Destroy()
		end
	})

	settingsTab:AddButton({
		Name = "Hide GUI",
		Callback = function()
			mainWindow.Visible = false
		end
	})

	settingsButton.MouseButton1Click:Connect(function()
		for _, t in ipairs(tabs) do
			if t.Name == "Settings" then
				SelectTab(t)
				break
			end
		end
	end)

	FrutyLib:Init()
	return WindowAPI
end

return FrutyLib
