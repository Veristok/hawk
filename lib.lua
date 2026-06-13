--[[
		local Library = loadstring(game:HttpGet("https://gitea.com/opc/fenrir/raw/branch/main/lib.luau"))()
		local Window  = Library:CreateWindow({ Title = "FENRIR", Version = "v0.1" })
		local Tab     = Window:AddTab({ Name = "Aim", Icon = "rbxassetid://93150019097402" })
		local Section = Tab:AddSection({ Name = "Ragebot", Side = "Left" })

		Section:AddToggle({ Name = "Enable ragebot", Default = true,  Callback = function(v) end })
		Section:AddSlider({ Name = "Hit chance",      Min = 0, Max = 100, Default = 0, Suffix = "%", Callback = function(v) end })
		Section:AddDropdown({ Name = "Body aimbot",  Options = {"Default","Head","Body"}, Default = "Default", Callback = function(v) end })
		Section:AddButton({ Name = "Button", Callback = function() end })
		Section:AddKeybind({ Name = "Toggle", Default = Enum.KeyCode.E, Callback = function(key) end })
		Section:AddTextbox({ Name = "Name", Default = "", Placeholder = "...", Callback = function(t) end })
]]

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")

local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer:GetMouse()

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) or (UserInputService.TouchEnabled and #UserInputService:GetTouchActive() > 0)

local Sizes = IsMobile and {
    WindowWidth = 360, WindowHeight = 230,
    SidebarWidth = 70, ContentOffsetX = 80,
    FontSize = 11, RowHeight = 38,
    ToggleWidth = 36, ToggleHeight = 18, KnobSize = 14,
    SliderWidth = 55, SliderHeight = 18,
    DropdownWidth = 90, DropdownHeight = 22,
    ButtonHeight = 28, TextboxWidth = 120, TextboxHeight = 22,
    WatermarkWidth = 360, WatermarkOffset = -380,
} or {
    WindowWidth = 760, WindowHeight = 480,
    SidebarWidth = 70, ContentOffsetX = 80,
    FontSize = 13, RowHeight = 26,
    ToggleWidth = 36, ToggleHeight = 18, KnobSize = 14,
    SliderWidth = 44, SliderHeight = 14,
    DropdownWidth = 90, DropdownHeight = 22,
    ButtonHeight = 28, TextboxWidth = 120, TextboxHeight = 22,
    WatermarkWidth = 360, WatermarkOffset = -380,
}

local Theme = {
	Accent       = Color3.fromRGB(124, 106, 182),
	AccentDim    = Color3.fromRGB(78,  74,  94),
	Background   = Color3.fromRGB(14,  13,  17),
	Surface      = Color3.fromRGB(13,  13,  18),
	Surface2     = Color3.fromRGB(20,  19,  26),
	Surface3     = Color3.fromRGB(28,  26,  37),
	Border       = Color3.fromRGB(40,  38,  55),
	Separator    = Color3.fromRGB(64,  64,  89),
	Text         = Color3.fromRGB(255, 255, 255),
	TextDim      = Color3.fromRGB(150, 144, 170),
	TextDisabled = Color3.fromRGB(78,  74,  94),
	ToggleOff    = Color3.fromRGB(45,  43,  62),
	BlurAsset    = "rbxassetid://119005000702500",
	LogoAsset    = "rbxassetid://119629811707415",
	HexAsset     = "rbxassetid://2785153010",
}

local function tween(obj, time, props, style, dir)
	local info = TweenInfo.new(time or 0.18,
		style or Enum.EasingStyle.Quad,
		dir   or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function new(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(parent, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color        = color or Theme.Border,
		Thickness    = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent       = parent,
	})
end

local function padding(parent, p)
	p = p or 0
	if type(p) == "number" then p = { p, p, p, p } end
	return new("UIPadding", {
		PaddingTop    = UDim.new(0, p[1]),
		PaddingRight  = UDim.new(0, p[2]),
		PaddingBottom = UDim.new(0, p[3]),
		PaddingLeft   = UDim.new(0, p[4]),
		Parent        = parent,
	})
end

local function ripple(button)
	button.ClipsDescendants = true
	button.MouseButton1Down:Connect(function(x, y)
		local circle = new("Frame", {
			Parent              = button,
			BackgroundColor3    = Theme.Accent,
			BackgroundTransparency = 0.7,
			BorderSizePixel     = 0,
			AnchorPoint         = Vector2.new(0.5, 0.5),
			Position            = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
			Size                = UDim2.new(0, 0, 0, 0),
			ZIndex              = button.ZIndex + 1,
		})
		corner(circle, 999)
		local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
		tween(circle, 0.4, { Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1 })
		task.delay(0.45, function() circle:Destroy() end)
	end)
end

local Library = {}
Library.__index = Library
Library.Flags = {}

local function makeRow(content, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height or 26)
	row.BackgroundTransparency = 1
	row.Parent = content
	return row
end

Library.Components = {}

	function Library.Components:AddToggle(o)
		o = o or {}
		local Toggle = { Value = o.Default or false, Callback = o.Callback or function() end }

		local row = makeRow(self.Content, Sizes.RowHeight)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Toggle",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = Sizes.FontSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local switch = new("Frame", {
			Size = UDim2.new(0, Sizes.ToggleWidth, 0, Sizes.ToggleHeight),
			Position = UDim2.new(1, -36, 0.5, -9),
			BackgroundColor3 = Theme.ToggleOff,
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(switch, 999)

		local knob = new("Frame", {
			Size = UDim2.new(0, Sizes.KnobSize, 0, Sizes.KnobSize),
			Position = UDim2.new(0, 2, 0.5, -7),
			BackgroundColor3 = Theme.Text,
			BorderSizePixel = 0,
			Parent = switch,
		})
		corner(knob, 999)

		local function update()
			if Toggle.Value then
				tween(switch, 0.18, { BackgroundColor3 = Theme.Accent })
				tween(knob,   0.18, { Position = UDim2.new(1, -16, 0.5, -7) })
				tween(label,  0.18, { TextColor3 = Theme.Text })
			else
				tween(switch, 0.18, { BackgroundColor3 = Theme.ToggleOff })
				tween(knob,   0.18, { Position = UDim2.new(0, 2, 0.5, -7) })
				tween(label,  0.18, { TextColor3 = Theme.TextDim })
			end
		end

		local btn = new("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			Parent = row,
		})
		btn.MouseButton1Click:Connect(function()
			Toggle.Value = not Toggle.Value
			update()
			Toggle.Callback(Toggle.Value)
		end)

		function Toggle:Set(v)
			Toggle.Value = v and true or false
			update()
			Toggle.Callback(Toggle.Value)
		end

		update()
		if o.Flag then Library.Flags[o.Flag] = Toggle end
		return Toggle
	end

	function Library.Components:AddSlider(o)
		o = o or {}
		local min, max = o.Min or 0, o.Max or 100
		local Slider = {
			Value    = o.Default or min,
			Callback = o.Callback or function() end,
			Suffix   = o.Suffix or "",
			Decimals = o.Decimals or 0,
		}

		local row = makeRow(self.Content, Sizes.RowHeight)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -110, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Slider",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = Sizes.FontSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local valueLbl = new("TextLabel", {
			Size = UDim2.new(0, 40, 1, 0),
			Position = UDim2.new(1, -90, 0, 0),
			BackgroundTransparency = 1,
			Text = "0" .. Slider.Suffix,
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})

		local barFrame = new("Frame", {
			Size = UDim2.new(0, Sizes.SliderWidth, 0, Sizes.SliderHeight),
			Position = UDim2.new(1, -44, 0.5, -7),
			BackgroundTransparency = 1,
			Parent = row,
		})
		local SEGS = 5
		local segments = {}
		for i = 1, SEGS do
			local seg = new("Frame", {
				Size = UDim2.new(0, 4, 1, 0),
				Position = UDim2.new(0, (i-1) * 9, 0, 0),
				BackgroundColor3 = Theme.ToggleOff,
				BorderSizePixel = 0,
				Parent = barFrame,
			})
			corner(seg, 2)
			segments[i] = seg
		end

		local function round(n)
			local mult = 10 ^ Slider.Decimals
			return math.floor(n * mult + 0.5) / mult
		end

		local function update(noCb)
			local v = math.clamp(Slider.Value, min, max)
			Slider.Value = round(v)
			local ratio = (v - min) / (max - min)
			if Slider.Decimals > 0 then
				valueLbl.Text = string.format("%."..Slider.Decimals.."f", Slider.Value) .. Slider.Suffix
			else
				valueLbl.Text = tostring(math.floor(Slider.Value)) .. Slider.Suffix
			end
			local filled = math.floor(ratio * SEGS + 0.5)
			for i, seg in ipairs(segments) do
				local target = (i <= filled) and Theme.Accent or Theme.ToggleOff
				tween(seg, 0.12, { BackgroundColor3 = target })
			end
			if not noCb then Slider.Callback(Slider.Value) end
		end

		barFrame.Active = true
		local hitArea = new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 12, 1, 8),
			Position = UDim2.new(0, -6, 0, -4),
			ZIndex = 2,
			Parent = barFrame,
		})
		local dragging = false
		local dragMoveConn, dragEndConn
		local function applyPos(px)
			local ratio = math.clamp((px - barFrame.AbsolutePosition.X) / barFrame.AbsoluteSize.X, 0, 1)
			Slider.Value = min + (max - min) * ratio
			update()
		end
		hitArea.MouseButton1Down:Connect(function()
			dragging = true
			applyPos(UserInputService:GetMouseLocation().X)
			if dragMoveConn then dragMoveConn:Disconnect() end
			if dragEndConn  then dragEndConn:Disconnect()  end
			dragMoveConn = UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					applyPos(input.Position.X)
				end
			end)
			dragEndConn = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
					if dragMoveConn then dragMoveConn:Disconnect() dragMoveConn = nil end
					if dragEndConn  then dragEndConn:Disconnect()  dragEndConn  = nil end
				end
			end)
		end)
		hitArea.TouchTap:Connect(function(touchPos)
			applyPos(touchPos[1].X)
		end)

		function Slider:Set(v) Slider.Value = v; update() end

		update(true)
		if o.Flag then Library.Flags[o.Flag] = Slider end
		return Slider
	end

	function Library.Components:AddDropdown(o)
		o = o or {}
		local Dropdown = {
			Options  = o.Options or {},
			Value    = o.Default or (o.Options and o.Options[1]) or "",
			Callback = o.Callback or function() end,
			Open     = false,
		}

		local row = makeRow(self.Content, Sizes.RowHeight)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -100, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Dropdown",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = Sizes.FontSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local box = new("TextButton", {
			Size = UDim2.new(0, Sizes.DropdownWidth, 0, Sizes.DropdownHeight),
			Position = UDim2.new(1, -90, 0.5, -11),
			BackgroundColor3 = Theme.Surface3,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(box, 4)
		stroke(box, Theme.Border, 1, 0.6)

		local valueLbl = new("TextLabel", {
			Size = UDim2.new(1, -22, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(Dropdown.Value),
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})

		local arrow = new("TextLabel", {
			Size = UDim2.new(0, 16, 1, 0),
			Position = UDim2.new(1, -18, 0, 0),
			BackgroundTransparency = 1,
			Text = "+",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			Parent = box,
		})

		local list = new("Frame", {
			Size = UDim2.new(0, 90, 0, 0),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 1000,
			Parent = Library.__activePopups,
		})
		corner(list, 4)
		stroke(list, Theme.Border, 1, 0.4)
		local layout = new("UIListLayout", { Parent = list })
		new("UIPadding", { PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3), Parent = list })

		local function positionList()
			local abs = box.AbsolutePosition
			local size = box.AbsoluteSize
			list.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
			list.Size = UDim2.fromOffset(size.X, list.Size.Y.Offset)
		end

		local function rebuild()
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for _, opt in ipairs(Dropdown.Options) do
				local b = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Surface3,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = tostring(opt),
					TextColor3 = (opt == Dropdown.Value) and Theme.Accent or Theme.TextDim,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					ZIndex = 51,
					Parent = list,
				})
				b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundTransparency = 0.6 }) end)
				b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundTransparency = 1 }) end)
				b.MouseButton1Click:Connect(function()
					Dropdown.Value = opt
					valueLbl.Text  = tostring(opt)
					Dropdown.Open  = false
					tween(list, 0.12, { Size = UDim2.new(0, 90, 0, 0) })
					tween(arrow, 0.12, { Rotation = 0 })
					task.delay(0.13, function() list.Visible = false end)
					for _, child in ipairs(list:GetChildren()) do
						if child:IsA("TextButton") then
							child.TextColor3 = (child.Text == tostring(opt)) and Theme.Accent or Theme.TextDim
						end
					end
					Dropdown.Callback(opt)
				end)
			end
		end

		box.MouseButton1Click:Connect(function()
			Dropdown.Open = not list.Visible
			if Dropdown.Open then
				positionList()
				list.Visible = true
				local w = box.AbsoluteSize.X
				local h = #Dropdown.Options * 22 + 6
				tween(list, 0.15, { Size = UDim2.fromOffset(w, h) })
				arrow.Text = "-"
			else
				tween(list, 0.12, { Size = UDim2.fromOffset(box.AbsoluteSize.X, 0) })
				arrow.Text = "+"
				task.delay(0.13, function() list.Visible = false end)
			end
		end)

		function Dropdown:Set(v)
			Dropdown.Value = v
			valueLbl.Text = tostring(v)
			Dropdown.Callback(v)
			rebuild()
		end
		function Dropdown:SetOptions(opts)
			Dropdown.Options = opts
			rebuild()
		end

		rebuild()
		if o.Flag then Library.Flags[o.Flag] = Dropdown end
		return Dropdown
	end

	function Library.Components:AddButton(o)
		o = o or {}
		local Button = { Callback = o.Callback or function() end }

		local row = makeRow(self.Content, Sizes.ButtonHeight)
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			Text = o.Name or "Button",
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = Sizes.FontSize,
			AutoButtonColor = false,
			Parent = row,
		})
		corner(b, 6)
		stroke(b, Theme.Border, 1, 0.4)
		ripple(b)

		b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = Theme.Border }) end)
		b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = Theme.Surface3 }) end)
		b.MouseButton1Click:Connect(function() Button.Callback() end)

		return Button
	end

	Library._PressedInputs = Library._PressedInputs or {}
	Library._SideMouseSupported = false
	do
		local _P = Library._PressedInputs
		if not Library._InputTrackerInstalled then
			Library._InputTrackerInstalled = true
			UserInputService.InputBegan:Connect(function(input)
				_P[input.UserInputType] = true
				if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then _P[input.KeyCode] = true end
			end)
			UserInputService.InputEnded:Connect(function(input)
				_P[input.UserInputType] = nil
				if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then _P[input.KeyCode] = nil end
			end)
			local ok = pcall(function() return iskeydown(0x05) end)
			Library._SideMouseSupported = ok
			if ok then
				task.spawn(function()
					while true do
						local s, m4 = pcall(iskeydown, 0x05)
						local _, m5 = pcall(iskeydown, 0x06)
						_P["MB4"] = (s and m4) and true or nil
						_P["MB5"] = (s and m5) and true or nil
						task.wait()
					end
				end)
			end
		end
	end

	function Library.Components:AddKeybind(o)
		o = o or {}
		local Keybind = {
			Value     = o.Default or Enum.KeyCode.Unknown,
			Callback  = o.Callback or function() end,
			Listening = false,
		}
		local _P = Library._PressedInputs

		local function displayName(v)
			if typeof(v) == "string" then return v end
			if typeof(v) == "EnumItem" then
				if v.EnumType == Enum.UserInputType then
					if v == Enum.UserInputType.MouseButton1 then return "MB1" end
					if v == Enum.UserInputType.MouseButton2 then return "MB2" end
					if v == Enum.UserInputType.MouseButton3 then return "MB3" end
					return v.Name
				end
				return v.Name
			end
			return "None"
		end

		function Keybind:IsPressed()
			local v = Keybind.Value
			if typeof(v) == "string" then
				if v == "MB4" then local ok, d = pcall(iskeydown, 0x05); return ok and (d == true) or false end
				if v == "MB5" then local ok, d = pcall(iskeydown, 0x06); return ok and (d == true) or false end
				return false
			end
			if typeof(v) ~= "EnumItem" then return false end
			if v.EnumType == Enum.KeyCode then
				if v == Enum.KeyCode.Unknown then return false end
				return UserInputService:IsKeyDown(v) or _P[v] == true
			elseif v.EnumType == Enum.UserInputType then
				if v == Enum.UserInputType.MouseButton1
				or v == Enum.UserInputType.MouseButton2
				or v == Enum.UserInputType.MouseButton3 then
					return UserInputService:IsMouseButtonPressed(v) or _P[v] == true
				end
				return _P[v] == true
			end
			return false
		end

		local row = makeRow(self.Content, 26)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -90, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Keybind",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local box = new("TextButton", {
			Size = UDim2.new(0, 80, 0, 22),
			Position = UDim2.new(1, -80, 0.5, -11),
			BackgroundColor3 = Theme.Surface3,
			AutoButtonColor = false,
			Text = "[" .. displayName(Keybind.Value) .. "]",
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(box, 4)
		stroke(box, Theme.Border, 1, 0.6)

		box.MouseButton1Click:Connect(function()
			Keybind.Listening = true
			box.Text = "[...]"
			tween(box, 0.12, { BackgroundColor3 = Theme.Accent })
		end)

		task.spawn(function()
			while box and box.Parent do
				if Keybind.Listening and Library._SideMouseSupported then
					local _, m4 = pcall(iskeydown, 0x05)
					local _, m5 = pcall(iskeydown, 0x06)
					if m4 then
						Keybind.Value = "MB4"
						Keybind.Listening = false
						box.Text = "[MB4]"
						tween(box, 0.12, { BackgroundColor3 = Theme.Surface3 })
					elseif m5 then
						Keybind.Value = "MB5"
						Keybind.Listening = false
						box.Text = "[MB5]"
						tween(box, 0.12, { BackgroundColor3 = Theme.Surface3 })
					end
				end
				task.wait(0.03)
			end
		end)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if Keybind.Listening then
				local captured
				local it = input.UserInputType
				if it == Enum.UserInputType.Keyboard then
					captured = input.KeyCode
				elseif it ~= Enum.UserInputType.Focus
				   and it ~= Enum.UserInputType.MouseMovement
				   and it ~= Enum.UserInputType.MouseWheel
				   and it ~= Enum.UserInputType.Touch
				   and it ~= Enum.UserInputType.TextInput
				   and it ~= Enum.UserInputType.None then
					captured = it
				end
				if captured then
					Keybind.Value = captured
					Keybind.Listening = false
					box.Text = "[" .. displayName(captured) .. "]"
					tween(box, 0.12, { BackgroundColor3 = Theme.Surface3 })
				end
				return
			end
			if gpe then return end
			local v = Keybind.Value
			if typeof(v) == "string" then return end
			if typeof(v) ~= "EnumItem" then return end
			if v.EnumType == Enum.KeyCode and input.KeyCode == v then
				Keybind.Callback(v)
			elseif v.EnumType == Enum.UserInputType and input.UserInputType == v then
				Keybind.Callback(v)
			end
		end)

		function Keybind:Set(k)
			Keybind.Value = k
			box.Text = "[" .. displayName(k) .. "]"
		end

		if o.Flag then Library.Flags[o.Flag] = Keybind end
		return Keybind
	end

	function Library.Components:AddTextbox(o)
		o = o or {}
		local Textbox = {
			Value    = o.Default or "",
			Callback = o.Callback or function() end,
		}

		local row = makeRow(self.Content, Sizes.RowHeight)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -130, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Input",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = Sizes.FontSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local box = new("Frame", {
			Size = UDim2.new(0, Sizes.TextboxWidth, 0, Sizes.TextboxHeight),
			Position = UDim2.new(1, -120, 0.5, -11),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(box, 4)
		local boxStroke = stroke(box, Theme.Border, 1, 0.6)

		local input = new("TextBox", {
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Text = Textbox.Value,
			PlaceholderText = o.Placeholder or "",
			PlaceholderColor3 = Theme.TextDisabled,
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = box,
		})

		input.Focused:Connect(function()
			tween(boxStroke, 0.12, { Color = Theme.Accent, Transparency = 0 })
		end)
		input.FocusLost:Connect(function(enter)
			tween(boxStroke, 0.12, { Color = Theme.Border, Transparency = 0.6 })
			Textbox.Value = input.Text
			Textbox.Callback(input.Text, enter)
		end)

		function Textbox:Set(v) Textbox.Value = v; input.Text = v end

		if o.Flag then Library.Flags[o.Flag] = Textbox end
		return Textbox
	end

	function Library.Components:AddMultiDropdown(o)
		o = o or {}
		local Multi = {
			Options  = o.Options or {},
			Values   = {},
			Callback = o.Callback or function() end,
			Open     = false,
			Max      = o.Max or math.huge,
		}

		if type(o.Default) == "table" then
			for _, v in ipairs(o.Default) do Multi.Values[v] = true end
		end

		local row = makeRow(self.Content, 26)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -130, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Multi",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local box = new("TextButton", {
			Size = UDim2.new(0, 120, 0, 22),
			Position = UDim2.new(1, -120, 0.5, -11),
			BackgroundColor3 = Theme.Surface3,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(box, 4)
		stroke(box, Theme.Border, 1, 0.6)

		local valueLbl = new("TextLabel", {
			Size = UDim2.new(1, -22, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "None",
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = box,
		})

		local arrow = new("TextLabel", {
			Size = UDim2.new(0, 16, 1, 0),
			Position = UDim2.new(1, -18, 0, 0),
			BackgroundTransparency = 1,
			Text = "+",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			Parent = box,
		})

		local list = new("ScrollingFrame", {
			Size = UDim2.new(0, 120, 0, 0),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			ZIndex = 1000,
			Parent = Library.__activePopups,
		})
		local function positionList()
			local abs = box.AbsolutePosition
			local size = box.AbsoluteSize
			list.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
		end
		corner(list, 4)
		stroke(list, Theme.Border, 1, 0.4)
		new("UIListLayout", { Padding = UDim.new(0,2), Parent = list })
		new("UIPadding", { PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3), Parent = list })

		local function refreshLabel()
			local picked = {}
			for _, v in ipairs(Multi.Options) do
				if Multi.Values[v] then table.insert(picked, tostring(v)) end
			end
			if #picked == 0 then
				valueLbl.Text = "None"
				valueLbl.TextColor3 = Theme.TextDim
			elseif #picked == 1 then
				valueLbl.Text = picked[1]
				valueLbl.TextColor3 = Theme.Text
			else
				valueLbl.Text = #picked .. " selected"
				valueLbl.TextColor3 = Theme.Text
			end
		end

		local entries = {}
		local function rebuild()
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			entries = {}
			for _, opt in ipairs(Multi.Options) do
				local b = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Surface3,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 51,
					Parent = list,
				})
				local check = new("Frame", {
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(0, 6, 0.5, -6),
					BackgroundColor3 = Theme.ToggleOff,
					BorderSizePixel = 0,
					ZIndex = 52,
					Parent = b,
				})
				corner(check, 3)
				local tick = new("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "X",
					TextColor3 = Theme.Text,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					ZIndex = 53,
					Visible = false,
					Parent = check,
				})
				new("TextLabel", {
					Size = UDim2.new(1, -28, 1, 0),
					Position = UDim2.new(0, 24, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(opt),
					TextColor3 = Theme.TextDim,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 52,
					Parent = b,
				})
				local function refresh()
					if Multi.Values[opt] then
						tween(check, 0.12, { BackgroundColor3 = Theme.Accent })
						tick.Visible = true
					else
						tween(check, 0.12, { BackgroundColor3 = Theme.ToggleOff })
						tick.Visible = false
					end
				end
				b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundTransparency = 0.6 }) end)
				b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundTransparency = 1 }) end)
				b.MouseButton1Click:Connect(function()
					if Multi.Values[opt] then
						Multi.Values[opt] = nil
					else
						local count = 0
						for _ in pairs(Multi.Values) do count = count + 1 end
						if count >= Multi.Max then return end
						Multi.Values[opt] = true
					end
					refresh()
					refreshLabel()
					Multi.Callback(Multi:Get())
				end)
				refresh()
				entries[opt] = { btn = b, refresh = refresh }
			end
		end

		box.MouseButton1Click:Connect(function()
			Multi.Open = not list.Visible
			if Multi.Open then
				positionList()
				list.Visible = true
				local w = box.AbsoluteSize.X
				local h = math.min(#Multi.Options, 6) * 24 + 6
				tween(list, 0.15, { Size = UDim2.fromOffset(w, h) })
				arrow.Text = "-"
			else
				tween(list, 0.12, { Size = UDim2.fromOffset(box.AbsoluteSize.X, 0) })
				arrow.Text = "+"
				task.delay(0.13, function() list.Visible = false end)
			end
		end)

		function Multi:Get()
			local t = {}
			for _, v in ipairs(Multi.Options) do
				if Multi.Values[v] then table.insert(t, v) end
			end
			return t
		end
		function Multi:Set(tbl)
			Multi.Values = {}
			for _, v in ipairs(tbl or {}) do Multi.Values[v] = true end
			for _, e in pairs(entries) do e.refresh() end
			refreshLabel()
		end
		function Multi:SetOptions(opts)
			Multi.Options = opts
			rebuild()
			refreshLabel()
		end

		rebuild()
		refreshLabel()
		if o.Flag then Library.Flags[o.Flag] = Multi end
		return Multi
	end

	function Library.Components:AddColorpicker(o)
		o = o or {}
		local Picker = {
			Value    = o.Default or Color3.fromRGB(124, 106, 182),
			Alpha    = o.Alpha == nil and 1 or o.Alpha,
			Callback = o.Callback or function() end,
			Open     = false,
		}

		local row = makeRow(self.Content, 26)
		local label = new("TextLabel", {
			Size = UDim2.new(1, -34, 1, 0),
			BackgroundTransparency = 1,
			Text = o.Name or "Color",
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local swatch = new("TextButton", {
			Size = UDim2.new(0, 28, 0, 18),
			Position = UDim2.new(1, -28, 0.5, -9),
			BackgroundColor3 = Picker.Value,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(swatch, 4)
		stroke(swatch, Theme.Border, 1, 0.4)

		local popup = new("Frame", {
			Size = UDim2.fromOffset(220, 254),
			BackgroundColor3 = Theme.Surface,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 1000,
			Parent = Library.__activePopups,
		})
		local function positionPopup()
			local abs = swatch.AbsolutePosition
			local size = swatch.AbsoluteSize
			popup.Position = UDim2.fromOffset(abs.X + size.X - 220, abs.Y + size.Y + 6)
		end
		corner(popup, 6)
		stroke(popup, Theme.Border, 1, 0.4)

		local sv = new("ImageButton", {
			Size = UDim2.new(1, -16, 0, 130),
			Position = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = Color3.fromHSV(0, 1, 1),
			AutoButtonColor = false,
			Image = "",
			BorderSizePixel = 0,
			ZIndex = 61,
			Parent = popup,
		})
		corner(sv, 4)

		local whiteGrad = new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = sv,
		})

		local blackOverlay = new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0,0,0),
			BorderSizePixel = 0,
			ZIndex = 62,
			Parent = sv,
		})
		corner(blackOverlay, 4)
		new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = blackOverlay,
		})

		local svCursor = new("Frame", {
			Size = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderColor3 = Color3.fromRGB(0,0,0),
			BorderSizePixel = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 63,
			Parent = sv,
		})
		corner(svCursor, 999)

		local hue = new("ImageButton", {
			Size = UDim2.new(1, -16, 0, 14),
			Position = UDim2.new(0, 8, 0, 144),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			AutoButtonColor = false,
			Image = "",
			BorderSizePixel = 0,
			ZIndex = 61,
			Parent = popup,
		})
		corner(hue, 4)
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255,   0,   0)),
				ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255,   0)),
				ColorSequenceKeypoint.new(0.333, Color3.fromRGB(  0, 255,   0)),
				ColorSequenceKeypoint.new(0.500, Color3.fromRGB(  0, 255, 255)),
				ColorSequenceKeypoint.new(0.667, Color3.fromRGB(  0,   0, 255)),
				ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,   0, 255)),
				ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255,   0,   0)),
			}),
			Parent = hue,
		})
		local hueCursor = new("Frame", {
			Size = UDim2.new(0, 3, 1, 4),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderColor3 = Color3.fromRGB(0,0,0),
			BorderSizePixel = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			ZIndex = 63,
			Parent = hue,
		})

		local alpha = new("ImageButton", {
			Size = UDim2.new(1, -16, 0, 14),
			Position = UDim2.new(0, 8, 0, 164),
			BackgroundColor3 = Picker.Value,
			AutoButtonColor = false,
			Image = "",
			BorderSizePixel = 0,
			ZIndex = 61,
			Parent = popup,
		})
		corner(alpha, 4)
		local alphaGrad = new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = alpha,
		})
		local alphaCursor = new("Frame", {
			Size = UDim2.new(0, 3, 1, 4),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderColor3 = Color3.fromRGB(0,0,0),
			BorderSizePixel = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			ZIndex = 63,
			Parent = alpha,
		})

		local hex = new("TextBox", {
			Size = UDim2.new(1, -16, 0, 18),
			Position = UDim2.new(0, 8, 0, 184),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			Text = "#7C6AB6",
			TextColor3 = Theme.Text,
			Font = Enum.Font.Code,
			TextSize = 12,
			ClearTextOnFocus = false,
			ZIndex = 1001,
			Parent = popup,
		})
		corner(hex, 3)

		local function rgbField(x, char)
			local wrap = new("Frame", {
				Size = UDim2.new(0, 64, 0, 22),
				Position = UDim2.new(0, x, 0, 208),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
				ZIndex = 1001,
				Parent = popup,
			})
			corner(wrap, 3)
			new("TextLabel", {
				Size = UDim2.new(0, 14, 1, 0),
				Position = UDim2.new(0, 4, 0, 0),
				BackgroundTransparency = 1,
				Text = char,
				TextColor3 = Theme.AccentDim,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				ZIndex = 1002,
				Parent = wrap,
			})
			local tb = new("TextBox", {
				Size = UDim2.new(1, -22, 1, 0),
				Position = UDim2.new(0, 20, 0, 0),
				BackgroundTransparency = 1,
				Text = "0",
				TextColor3 = Theme.Text,
				Font = Enum.Font.Code,
				TextSize = 12,
				ClearTextOnFocus = false,
				ZIndex = 1002,
				Parent = wrap,
			})
			return tb
		end
		local rIn = rgbField(8,   "R")
		local gIn = rgbField(78,  "G")
		local bIn = rgbField(148, "B")

		local h, s, v = 0, 0, 1
		do
			h, s, v = Picker.Value:ToHSV()
		end

		local function fireUpdate(silent)
			local c = Color3.fromHSV(h, s, v)
			Picker.Value = c
			swatch.BackgroundColor3 = c
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			alpha.BackgroundColor3 = c
			svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
			alphaCursor.Position = UDim2.new(Picker.Alpha, 0, 0.5, 0)
			local R = math.floor(c.R*255+0.5)
			local G = math.floor(c.G*255+0.5)
			local B = math.floor(c.B*255+0.5)
			hex.Text = string.format("#%02X%02X%02X", R, G, B)
			rIn.Text = tostring(R)
			gIn.Text = tostring(G)
			bIn.Text = tostring(B)
			if not silent then Picker.Callback(c, Picker.Alpha) end
		end

		local function bindDrag(target, onMove)
			local dragging = false
			target.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					onMove(input.Position)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					onMove(input.Position)
				end
			end)
		end

		bindDrag(sv, function(pos)
			local rx = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			local ry = math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			s, v = rx, 1 - ry
			fireUpdate()
		end)
		bindDrag(hue, function(pos)
			h = math.clamp((pos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
			fireUpdate()
		end)
		bindDrag(alpha, function(pos)
			Picker.Alpha = math.clamp((pos.X - alpha.AbsolutePosition.X) / alpha.AbsoluteSize.X, 0, 1)
			fireUpdate()
		end)

		hex.FocusLost:Connect(function()
			local txt = hex.Text:gsub("#","")
			if #txt == 6 then
				local r = tonumber(txt:sub(1,2), 16)
				local g = tonumber(txt:sub(3,4), 16)
				local bl = tonumber(txt:sub(5,6), 16)
				if r and g and bl then
					h, s, v = Color3.fromRGB(r, g, bl):ToHSV()
					fireUpdate()
				end
			end
		end)

		local function rgbCommit()
			local r = math.clamp(tonumber(rIn.Text) or 0, 0, 255)
			local g = math.clamp(tonumber(gIn.Text) or 0, 0, 255)
			local b = math.clamp(tonumber(bIn.Text) or 0, 0, 255)
			h, s, v = Color3.fromRGB(r, g, b):ToHSV()
			fireUpdate()
		end
		rIn.FocusLost:Connect(rgbCommit)
		gIn.FocusLost:Connect(rgbCommit)
		bIn.FocusLost:Connect(rgbCommit)

		swatch.MouseButton1Click:Connect(function()
			Picker.Open = not popup.Visible
			if Picker.Open then positionPopup() end
			popup.Visible = Picker.Open
		end)

		UserInputService.InputBegan:Connect(function(input)
			if not popup.Visible then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
			   and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local m = UserInputService:GetMouseLocation()
			local function inside(g)
				if not g or not g.Parent then return false end
				local ap, az = g.AbsolutePosition, g.AbsoluteSize
				return m.X >= ap.X and m.X <= ap.X + az.X
				   and m.Y >= ap.Y and m.Y <= ap.Y + az.Y
			end
			if not inside(popup) and not inside(swatch) then
				popup.Visible = false
				Picker.Open = false
			end
		end)

		function Picker:Set(c, a)
			if c then h, s, v = c:ToHSV() end
			if a then Picker.Alpha = a end
			fireUpdate()
		end
		function Picker:Get() return Picker.Value, Picker.Alpha end

		fireUpdate()
		if o.Flag then Library.Flags[o.Flag] = Picker end
		return Picker
	end

	--[[ function Library.Components:AddPlayerList(o)
	o = o or {}
	local List = {
		Callbacks = o.Callbacks or {},  
		ActionLabels = o.Actions or { "Spectate", "Target", "Whitelist" },
	}

	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1, 0, 0, 220)
	wrap.BackgroundTransparency = 1
	wrap.Parent = self.Content

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundColor3 = Theme.Surface3
	scroll.BackgroundTransparency = 0.4
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Theme.Accent
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = wrap
	corner(scroll, 6)
	stroke(scroll, Theme.Border, 1, 0.6)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll
	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 4)
	listPad.PaddingBottom = UDim.new(0, 4)
	listPad.PaddingLeft = UDim.new(0, 4)
	listPad.PaddingRight = UDim.new(0, 4)
	listPad.Parent = scroll

	local rows = {}

	local function buildRow(plr)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 28)
		row.BackgroundColor3 = Theme.Surface2
		row.BackgroundTransparency = 0.4
		row.BorderSizePixel = 0
		row.Parent = scroll
		corner(row, 4)

		local avatar = Instance.new("ImageLabel")
		avatar.Size = UDim2.new(0, 22, 0, 22)
		avatar.Position = UDim2.new(0, 4, 0.5, -11)
		avatar.BackgroundColor3 = Theme.Surface
		avatar.BorderSizePixel = 0
		avatar.ScaleType = Enum.ScaleType.Crop
		avatar.Parent = row
		corner(avatar, 999)
		task.spawn(function()
			local ok, img = pcall(function()
				return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			 end)
			if ok and img then avatar.Image = img end
		end)

		local tag = ""
		if plr == LocalPlayer then
			tag = " (self)"
		else
			local ok, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
			if ok and isFriend then tag = " (friend)" end
		end

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -140, 1, 0)
		name.Position = UDim2.new(0, 32, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = plr.DisplayName .. tag
		name.TextColor3 = (plr == LocalPlayer) and Theme.Accent or Theme.Text
		name.Font = Enum.Font.GothamBold
		name.TextSize = 12
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Parent = row

		local nbtn = #List.ActionLabels
		for i, label in ipairs(List.ActionLabels) do
			local w = 32
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, w, 0, 18)
			b.Position = UDim2.new(1, -((nbtn - i + 1) * (w + 4)), 0.5, -9)
			b.BackgroundColor3 = Theme.Surface3
			b.AutoButtonColor = false
			b.Text = label:sub(1,1) 
			b.TextColor3 = Theme.TextDim
			b.Font = Enum.Font.GothamBold
			b.TextSize = 11
			b.BorderSizePixel = 0
			b.Parent = row
			corner(b, 3)
			local tipTxt = label
			b.MouseEnter:Connect(function()
				tween(b, 0.12, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text })
			end)
			b.MouseLeave:Connect(function()
				tween(b, 0.12, { BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.TextDim })
			end)
			b.MouseButton1Click:Connect(function()
				local cb = List.Callbacks[label]
				if cb then cb(plr) end
			end)
		end

		rows[plr] = row
	end

	local function removeRow(plr)
		if rows[plr] then rows[plr]:Destroy(); rows[plr] = nil end
	end

	for _, p in ipairs(Players:GetPlayers()) do buildRow(p) end
	Players.PlayerAdded:Connect(buildRow)
	Players.PlayerRemoving:Connect(removeRow)

	function List:Refresh()
		for p, r in pairs(rows) do r:Destroy() end
		rows = {}
		for _, p in ipairs(Players:GetPlayers()) do buildRow(p) end
	end

	return List
end ]]

function Library.Components:AddLabel(text)
		local row = makeRow(self.Content, 22)
		new("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = Theme.TextDim,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		return row
	end

	function Library.Components:AddSeparator()
		local row = makeRow(self.Content, 8)
		local sep = new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Theme.Separator,
			BorderSizePixel = 0,
			Parent = row,
		})
		local g = new("UIGradient", { Parent = sep })
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		return row
	end

function Library:CreateWindow(opts)
	opts = opts or {}
	local Window = setmetatable({
		Tabs       = {},
		ActiveTab  = nil,
		Title      = opts.Title   or "Aqua",
		Version    = opts.Version or "v0.1",
		GameName   = opts.GameName or "GET OUT",
		Dragging   = false,
	}, { __index = Library })

	local screen = new("ScreenGui", {
		Name              = "FenrirUI",
		ResetOnSpawn      = false,
		IgnoreGuiInset    = true,
		ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
		DisplayOrder      = 2147483647,
	})
	
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	screen.Parent = (ok and core) and core or LocalPlayer:WaitForChild("PlayerGui")
	
	Window.ScreenGui = screen

	local Popups = new("Frame", {
		Name = "Popups",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 999,
		Parent = screen,
	})
	Window.Popups = Popups
	Library.__activePopups = Popups

	local Main = new("Frame", {
		Name             = "Main",
		Size = UDim2.fromOffset(Sizes.WindowWidth, Sizes.WindowHeight),
		Position         = UDim2.fromScale(0.5, 0.5),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel  = 0,
		Parent           = screen,
	})
	corner(Main, 10)
	stroke(Main, Theme.Border, 1, 0.4)
	new("UISizeConstraint", { MinSize = Vector2.new(620, 400), MaxSize = Vector2.new(1100, 720), Parent = Main })

	new("ImageLabel", {
		Name = "Blur",
		Size  = UDim2.fromScale(1.231, 1.407),
		Position = UDim2.fromScale(-0.083, -0.183),
		BackgroundTransparency = 1,
		Image = Theme.BlurAsset,
		ImageColor3 = Color3.fromRGB(255,255,255),
		ZIndex = 0,
		Parent = Main,
	})
	Window.Main = Main

	local Sidebar = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, Sizes.SidebarWidth, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Main,
	})
	local TabsFrame
	Window.Sidebar = Sidebar
	Sidebar.Active = true

	do
		local dragStart, startMainPos, startTabsPos
		local tabsOffset
		local targetPos
		local lastMainPos = Main.Position
		Sidebar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				Window.Dragging = true
				dragStart = input.Position
				startMainPos  = Main.Position
				startTabsPos  = TabsFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						Window.Dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if Window.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				targetPos = UDim2.new(
					startMainPos.X.Scale, startMainPos.X.Offset + delta.X,
					startMainPos.Y.Scale, startMainPos.Y.Offset + delta.Y)
				TweenService:Create(Main,
					TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = targetPos }):Play()
				local tabsTarget = UDim2.new(
					startTabsPos.X.Scale, startTabsPos.X.Offset + delta.X,
					startTabsPos.Y.Scale, startTabsPos.Y.Offset + delta.Y)
				TweenService:Create(TabsFrame,
					TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0),
					{ Position = tabsTarget }):Play()
			end
		end)
	end

	local function buildVerticalText(parent, letters, gradRot)
		local stacked = ""
		for i = 1, string.len(letters) do
			stacked = stacked .. letters:sub(i, i) .. (i < string.len(letters) and "\n" or "")
		end
		local lbl = new("TextLabel", {
			Size = UDim2.new(1, 0, 0.35, 0),
			BackgroundTransparency = 1,
			Text = stacked,
			TextColor3 = Theme.Accent,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			Parent = parent,
		})
		local g = new("UIGradient", { Parent = lbl, Rotation = gradRot })
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,     0),
			NumberSequenceKeypoint.new(0.2,   0.7),
			NumberSequenceKeypoint.new(0.6,   0.7),
			NumberSequenceKeypoint.new(0.921, 1),
			NumberSequenceKeypoint.new(1,     1),
		})
		return lbl
	end

	local upText = buildVerticalText(Sidebar, "RIRNE", -90)
	upText.Position = UDim2.new(0, 0, 0.05, 0)

	local Logo = new("ImageLabel", {
		Name  = "Logo",
		Size  = UDim2.new(1, -10, 0, 70),
		Position = UDim2.new(0, 5, 0.5, -35),
		BackgroundTransparency = 1,
		Image = Theme.LogoAsset,
		ImageColor3 = Color3.fromRGB(255,255,255),
		ImageTransparency = 0.08,
		Parent = Sidebar,
	})
	local logoG = new("UIGradient", { Parent = Logo, Rotation = 90 })
	logoG.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   1),
		NumberSequenceKeypoint.new(0.1, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.9, 1),
		NumberSequenceKeypoint.new(1,   1),
	})

	local downText = buildVerticalText(Sidebar, "ENRIR", 90)
	downText.Position = UDim2.new(0, 0, 0.60, 0)

	local Content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -90, 1, -20),
		Position = UDim2.new(0, Sizes.ContentOffsetX, 0, 10),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = Main,
	})
	corner(Content, 8)
	stroke(Content, Theme.Border, 1, 0.6)
	Window.Content = Content

	local Pages = new("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Content,
	})
	Window.Pages = Pages

	TabsFrame = new("Frame", {
		Name = "Tabs",
		Size = UDim2.fromOffset(220, 220),
		Position = opts.TabsPosition or UDim2.new(0, 30, 0.5, -110),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = TabsFrame })
	Window.TabsFrame = TabsFrame

	Window.HexSlots = {
		{ x = 0.156, y = 0.027 }, 
		{ x = 0.470, y = 0.023 }, 
		{ x =-0.004, y = 0.304 }, 
		{ x = 0.310, y = 0.300 }, 
		{ x = 0.637, y = 0.300 }, 
		{ x = 0.156, y = 0.587 }, 
		{ x = 0.470, y = 0.579 }, 
	}

	do
		local dragging, ds, sp
		TabsFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; ds = input.Position; sp = TabsFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - ds
				TabsFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
	end

	local Watermark = new("Frame", {
		Name             = "Watermark",
		Size = UDim2.fromOffset(Sizes.WatermarkWidth, 36),
		Position = UDim2.new(1, Sizes.WatermarkOffset, 0, 14),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.2,
		BorderSizePixel  = 0,
		Parent           = screen,
	})
	corner(Watermark, 8)
	stroke(Watermark, Theme.Border, 1, 0.6)
	Window.Watermark = Watermark

	local wmPad = new("UIPadding", {
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		Parent = Watermark,
	})

	local wmList = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Watermark,
	})

	local slot = 0
	local function nextSlot()
		slot = slot + 1
		return slot
	end
	local function wmText(text, color, size)
		local lbl = new("TextLabel", {
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = color or Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = size or 13,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = nextSlot(),
			Parent = Watermark,
		})
		return lbl
	end
	local function wmSeparator()
		local s = new("Frame", {
			Size = UDim2.new(0, 1, 0.7, 0),
			BackgroundColor3 = Theme.Separator,
			BorderSizePixel = 0,
			LayoutOrder = nextSlot(),
			Parent = Watermark,
		})
		local g = new("UIGradient", { Parent = s, Rotation = 90 })
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,   1),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1,   1),
		})
		return s
	end

	local wmLogo = new("ImageLabel", {
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundTransparency = 1,
		Image = Theme.LogoAsset,
		ImageColor3 = Theme.Accent,
		LayoutOrder = nextSlot(),
		Parent = Watermark,
	})

	local GameName = wmText(Window.GameName, Theme.TextDim, 12)
	wmSeparator()
	local FPS  = wmText("0FPS", Theme.TextDim, 12)
	wmSeparator()
	local Ping = wmText("0PING", Theme.TextDim, 12)
	wmSeparator()
	local Time = wmText("00:00AM", Theme.Accent, 12)
	wmSeparator()
	local Version = wmText(Window.Version, Theme.TextDisabled, 11)

	pcall(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		local info = MarketplaceService:GetProductInfo(game.PlaceId)
		if info and info.Name then GameName.Text = string.upper(info.Name) end
	end)

	local stats = game:GetService("Stats")
	task.spawn(function()
		local fpsAcc, fpsCount = 0, 0
		local last = tick()
		while screen.Parent do
			local dt = RunService.RenderStepped:Wait()
			fpsAcc = fpsAcc + (1 / dt)
			fpsCount = fpsCount + 1
			if tick() - last >= 0.5 then
				last = tick()
				FPS.Text = math.floor(fpsAcc / fpsCount) .. "FPS"
				fpsAcc, fpsCount = 0, 0
				local okp, ping = pcall(function()
					return math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				if okp then Ping.Text = ping .. "PING" end
				local h = tonumber(os.date("%H")) or 0
				local m = os.date("%M")
				local suf = h >= 12 and "PM" or "AM"
				Time.Text = string.format("%02d:%s%s", h, m, suf)
			end
		end
	end)

	function Window:AddTab(o)
		o = o or {}
		local Tab = { Name = o.Name or ("Tab"..(#self.Tabs+1)), Icon = o.Icon }

		local idx  = #self.Tabs + 1
		local slot = self.HexSlots[idx]
		if not slot then
			warn("[Fenrir] Max 7 tabs supported in honeycomb layout — skipping " .. Tab.Name)
			return
		end

		local Hex = new("ImageLabel", {
			Name = Tab.Name,
			Size = UDim2.fromScale(0.383, 0.383),
			Position = UDim2.fromScale(slot.x, slot.y),
			BackgroundTransparency = 1,
			Image = Theme.HexAsset,
			ImageColor3 = Color3.fromRGB(30, 30, 40),
			ImageTransparency = 0.01,
			Parent = self.TabsFrame,
		})
		new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = Hex })

		local Btn = new("ImageButton", {
			Size = UDim2.fromScale(0.40, 0.40),
			Position = UDim2.fromScale(0.30, 0.30),
			BackgroundTransparency = 1,
			Image = Tab.Icon or "",
			ImageColor3 = Theme.AccentDim,
			ZIndex = 2,
			Parent = Hex,
		})
		Tab.Hex    = Hex
		Tab.Button = Btn

		local tip = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 6),
			Size = UDim2.new(0, 0, 0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Background,
			BorderSizePixel = 0,
			Text = " " .. Tab.Name .. " ",
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			Visible = false,
			ZIndex = 5,
			Parent = Hex,
		})
		corner(tip, 4)
		Btn.MouseEnter:Connect(function()
			tip.Visible = true
			if self.ActiveTab ~= Tab then tween(Btn, 0.15, { ImageColor3 = Theme.Text }) end
		end)
		Btn.MouseLeave:Connect(function()
			tip.Visible = false
			if self.ActiveTab ~= Tab then tween(Btn, 0.15, { ImageColor3 = Theme.AccentDim }) end
		end)

		local Page = new("ScrollingFrame", {
			Name = Tab.Name,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = self.Pages,
		})
		Tab.Page = Page

		local Left = new("Frame", {
			Name = "Left",
			Size = UDim2.new(0.5, -6, 1, 0),
			BackgroundTransparency = 1,
			Parent = Page,
		})
		local Right = new("Frame", {
			Name = "Right",
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0.5, 6, 0, 0),
			BackgroundTransparency = 1,
			Parent = Page,
		})
		new("UIListLayout", { Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Left })
		new("UIListLayout", { Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Right })
		Tab.LeftFrame  = Left
		Tab.RightFrame = Right

		Btn.MouseButton1Click:Connect(function() Window:SelectTab(Tab) end)

		function Tab:AddSection(s)
			s = s or {}
			local side = (s.Side == "Right") and Right or Left
			local Section = {}

			local frame = new("Frame", {
				Name = s.Name or "Section",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Surface2,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Parent = side,
			})
			corner(frame, 8)
			stroke(frame, Theme.Border, 1, 0.6)

			if s.Name then
				new("TextLabel", {
					Size = UDim2.new(1, -20, 0, 24),
					Position = UDim2.new(0, 10, 0, 6),
					BackgroundTransparency = 1,
					Text = s.Name,
					TextColor3 = Theme.Text,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame,
				})
			end

			local content = new("Frame", {
				Name = "Content",
				Position = UDim2.new(0, 10, 0, s.Name and 32 or 8),
				Size = UDim2.new(1, -20, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = frame,
			})
			new("UIListLayout", { Padding = UDim.new(0, IsMobile and 8 or 12), Parent = content })
			new("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = frame })

			Section.Frame = frame
			Section.Content = content

			Section.AddToggle        = Library.Components.AddToggle
			Section.AddSlider        = Library.Components.AddSlider
			Section.AddDropdown      = Library.Components.AddDropdown
			Section.AddMultiDropdown = Library.Components.AddMultiDropdown
			Section.AddColorpicker   = Library.Components.AddColorpicker
			Section.AddButton        = Library.Components.AddButton
			Section.AddKeybind       = Library.Components.AddKeybind
			Section.AddTextbox       = Library.Components.AddTextbox
			Section.AddLabel         = Library.Components.AddLabel
			Section.AddSeparator     = Library.Components.AddSeparator
			Section.AddPlayerList    = Library.Components.AddPlayerList

			return Section
		end

		table.insert(self.Tabs, Tab)
		if #self.Tabs == 1 then self:SelectTab(Tab) end
		return Tab
	end

	function Window:SelectTab(target)
		for _, child in ipairs(self.Popups:GetChildren()) do
			if child:IsA("GuiObject") then child.Visible = false end
		end
		for _, tab in ipairs(self.Tabs) do
			local isActive = tab == target
			tab.Page.Visible = isActive
			if isActive then
				tab.Hex.ZIndex = 3
				tab.Button.ZIndex = 4
				tween(tab.Hex,    0.18, { ImageColor3 = Theme.Accent, ImageTransparency = 0 })
				tween(tab.Button, 0.18, { ImageColor3 = Theme.Text })
				tab.Page.Position = UDim2.new(0, 12, 0, 0)
				tween(tab.Page, 0.25, { Position = UDim2.new(0,0,0,0) })
			else
				tab.Hex.ZIndex = 1
				tab.Button.ZIndex = 2
				tween(tab.Hex,    0.18, { ImageColor3 = Color3.fromRGB(30, 30, 40), ImageTransparency = 0.01 })
				tween(tab.Button, 0.18, { ImageColor3 = Theme.AccentDim })
			end
		end
		self.ActiveTab = target
	end
	function Window:SelectTabByName(name)
		for _, t in ipairs(self.Tabs) do
			if t.Name == name then self:SelectTab(t); return end
		end
	end

	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		local currentKey = (Library.Flags and Library.Flags.menu_key and Library.Flags.menu_key.Value) or toggleKey
		if input.KeyCode == currentKey then
			Main.Visible    = not Main.Visible
			TabsFrame.Visible = Main.Visible
			Watermark.Visible = Main.Visible
		end
	end)


	function Window:Destroy() screen:Destroy() end
	return Window
end

Library.IsMobile = IsMobile

return Library
