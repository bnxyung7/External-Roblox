-- BNXYUNG7 | modulo interno | no ejecutar directo: pasar por main_code.lua
local wait, spawn = task.wait, task.spawn

local Localplayer = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local hasTouch = UIS.TouchEnabled or not UIS.KeyboardEnabled
local RS = game:GetService("RunService")
local mouse = Localplayer:GetMouse()
local Camera = workspace.CurrentCamera
local espying = true
local spydown = 0.05
local CanAim = false
local fov = 100
local CLR = Color3.new(1,1,1)
local max = 300
local walkspeed = 0
local shooting = {}
local enabledaim = true
local shootteam = false
local advanced = false
local fovoutline = true
local cleaned = false
local connections = {}
local resources = {}
local activeSlider
local panelDragging = false
local panelDragStart
local panelStart
local fovCircle, fovDot
local mainPanel, menuScale
local viewportConnection
local shutdown

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

local function own(instance)
	resources[#resources + 1] = instance
	return instance
end

local function isPointInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

shutdown = function()
	if cleaned then
		return
	end
	cleaned = true
	CanAim = false
	activeSlider = nil
	panelDragging = false
	for index = #connections, 1, -1 do
		connections[index]:Disconnect()
		connections[index] = nil
	end
	for index = #resources, 1, -1 do
		resources[index]:Destroy()
		resources[index] = nil
	end
	_G.AIM_LOADED = false
	pcall(function() getgenv().AIM_LOADED = false end)
	print("[BNXYUNG7] Interfaz, FOV, ESP y conexiones eliminados.")
end

local screengui = own(Instance.new("ScreenGui"))
screengui.Name = "BNXYUNG7_UI"
screengui.ResetOnSpawn = false
screengui.IgnoreGuiInset = true
screengui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screengui.DisplayOrder = 9999
local parented = pcall(function() screengui.Parent = game:GetService("CoreGui") end)
if not parented then
	screengui.Parent = Localplayer:WaitForChild("PlayerGui")
end

local offset = 0
local functions = {function()
	track(UIS.InputEnded:Connect(function(input)
		if not cleaned and input.UserInputType == Enum.UserInputType.MouseButton2 then CanAim = false end
	end))
	track(UIS.InputBegan:Connect(function(input)
		if not cleaned and input.UserInputType == Enum.UserInputType.MouseButton2 then CanAim = true shootnearest() end
	end))
end}

functions[1]()

function int(args: {any})
	for _, item in args do
		if typeof(item) == "boolean" then
			if item then
				return 1
			else
				return 0
			end
		end
	end
end

keys = {
	A = false,
	S = false,
	D = false,
	W = false
}

track(UIS.InputBegan:Connect(function(key)
	if cleaned then return end
	if key.KeyCode == Enum.KeyCode.A then keys.A = true end
	if key.KeyCode == Enum.KeyCode.S then keys.S = true end
	if key.KeyCode == Enum.KeyCode.D then keys.D = true end
	if key.KeyCode == Enum.KeyCode.W then keys.W = true end
end))

track(UIS.InputEnded:Connect(function(key)
	if cleaned then return end
	if key.KeyCode == Enum.KeyCode.A then keys.A = false end
	if key.KeyCode == Enum.KeyCode.S then keys.S = false end
	if key.KeyCode == Enum.KeyCode.D then keys.D = false end
	if key.KeyCode == Enum.KeyCode.W then keys.W = false end
end))

track(RS.RenderStepped:Connect(function()
	if cleaned then return end
	if enabledaim then
		if CanAim then
			shootnearest()
		end
		if Localplayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Jumping or Localplayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then return end
		if keys.D or keys.A then
			Localplayer.Character.HumanoidRootPart.Velocity += (Localplayer.Character.HumanoidRootPart.CFrame.RightVector * walkspeed) * (int({keys.D}) - int({keys.A}))
		else
			Localplayer.Character.HumanoidRootPart.Velocity += (Localplayer.Character.HumanoidRootPart.CFrame.LookVector * walkspeed) * (int({keys.W}) - int({keys.S}))
		end
	end
end))

function shootnearest()
	table.clear(shooting)
	for _,player in game.Players:GetPlayers() do
		if player == Localplayer then continue end
		if player.Character and player.Character:FindFirstChild("Head") then
			local distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(Camera:WorldToScreenPoint(player.Character.Head.Position).X, Camera:WorldToScreenPoint(player.Character.Head.Position).Y)).Magnitude
			if advanced then if ((Localplayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > max) then continue end end
			shooting[distance] = player
		end
	end
	local shortest = math.huge
	for distance, player in shooting do
		local check = (player.Team ~= Localplayer.Team)
		if player.Team == nil then check = true end
		if shootteam then check = true end 
		if distance < shortest and check then
			if player.Character.Humanoid.Health == 0 then continue end
			local ray = Ray.new(Camera.CFrame.Position, (player.Character.Head.Position - Camera.CFrame.Position).Unit * 2000)
			local part = workspace:FindPartOnRayWithIgnoreList(ray, {Localplayer.Character})
			if part and (part:IsDescendantOf(player.Character) or not part.CanCollide) then
				shortest = distance
			end
		end
	end
	if shortest <= fov then
		shoot(shooting[shortest])
	end
end

function shoot(player: Player)
	if not player then return end
	local mouseRay = Camera:ScreenPointToRay(mouse.X, mouse.Y)
	local lookto = CFrame.lookAt(mouseRay.Origin, player.Character.Head.Position)
	-- local lookto = CFrame.lookAt(Camera.CFrame.Position, player.Character.Head.Position)
	if advanced then
		local distance = ((Localplayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position) / (max * 1.2)).Magnitude / 2
		local vel = (player.Character.HumanoidRootPart.Velocity * (0.20 + (Localplayer:GetNetworkPing() * (5 + distance))))
		local vel = Vector3.new(vel.x, vel.y / 6, vel.z)
		lookto = CFrame.lookAt(Camera.CFrame.Position, player.Character.HumanoidRootPart.Position + vel)
	end
	Camera.CFrame = lookto
end

function esp(char: Model)
	if cleaned then return end
	local player = game.Players:GetPlayerFromCharacter(char)
	local newpart = Instance.new("Frame")
	local gui = own(char:FindFirstChild("Esp-Decal") or Instance.new("BillboardGui"))
	for _, part in gui:GetChildren() do part:Destroy() end
	gui.Parent = screengui
	-- esp's the player's head --
	gui.Name = "Esp-Decal"
	gui.Size = UDim2.new(1,0,1,0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 1000
	gui.SizeOffset = Vector2.new(0,0)
	gui.ExtentsOffset = Vector3.new(0,0,0)
	gui.Adornee = char:FindFirstChild("Head") or char:WaitForChild("Head")
	gui.Active = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	newpart.Parent = gui
	newpart.ZIndex = 9999
	newpart.Size = UDim2.new(1,0,1,0)
	newpart.BorderColor3 = CLR
	newpart.BackgroundColor3 = CLR
	spawn(function()
		while not cleaned and player.Character do
			if Localplayer.Team == player.Team and Localplayer.Team ~= nil then newpart.Transparency = 1 else newpart.Transparency = 0.5 end
			task.wait(2)
		end
	end)
end

function temp_esp(char: Model)
	local player = game.Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not char.Head then return end
	local new = Instance.new("Frame")
	local dist = (Localplayer.Character.Position - char.Position).Magnitude
	new.Name = "Esp-Temp"
	new.Size = UDim2.new(0, 10, 0, 10)
	new.BorderColor3 = CLR
	new.BackgroundColor3 = CLR
	new.Parent = screengui
	new.ZIndex = 9999
	new.Size = UDim2.fromOffset(100/dist, 100/dist)
	new.Position = UDim2.new(0, Camera:WorldToScreenPoint(char.Head.Position).X, 0, Camera:WorldToScreenPoint(char.Head.Position).Y)
	if Localplayer.Team == player.Team and Localplayer.Team ~= nil then new.Transparency = 1 else new.Transparency = 0.5 end
	game.Debris:AddItem(new, spydown)
end

function drawCircle(value, color)
	if cleaned then return end
	if not fovCircle then
		fovCircle = own(Instance.new("Frame"))
		fovCircle.Name = "FovOutLine"
		fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		fovCircle.BackgroundTransparency = 1
		fovCircle.BorderSizePixel = 0
		fovCircle.ZIndex = 9998
		fovCircle.Parent = screengui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = fovCircle
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Parent = fovCircle
	end
	fovCircle.Size = UDim2.fromOffset(value * 2, value * 2)
	fovCircle.Position = UDim2.fromOffset(mouse.X, mouse.Y + offset)
	fovCircle.Visible = fovoutline
	fovCircle.UIStroke.Color = color
end

function drawDot(color)
	if cleaned then return end
	if not fovDot then
		fovDot = own(Instance.new("Frame"))
		fovDot.Name = "FovOutLine-Dot"
		fovDot.AnchorPoint = Vector2.new(0.5, 0.5)
		fovDot.BorderSizePixel = 0
		fovDot.ZIndex = 9999
		fovDot.Parent = screengui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = fovDot
	end
	fovDot.Size = UDim2.fromOffset(4, 4)
	fovDot.Position = UDim2.fromOffset(mouse.X, mouse.Y + offset)
	fovDot.BackgroundColor3 = color
	fovDot.Visible = fovoutline
end

function drawMain(color)
	local background = Color3.fromRGB(17, 19, 24)
	local surface = Color3.fromRGB(25, 28, 35)
	local border = Color3.fromRGB(43, 47, 57)
	local textColor = Color3.fromRGB(237, 239, 244)
	local muted = Color3.fromRGB(148, 156, 172)
	local inactive = Color3.fromRGB(64, 70, 83)
	local accent = Color3.fromRGB(255, 60, 60)
	local panelSize = Vector2.new(440, 428)

	mainPanel = Instance.new("Frame")
	mainPanel.Name = "main"
	mainPanel.Size = UDim2.fromOffset(panelSize.X, panelSize.Y)
	mainPanel.Position = UDim2.fromOffset(24, 24)
	mainPanel.BackgroundColor3 = background
	mainPanel.BorderSizePixel = 0
	mainPanel.Active = true
	mainPanel.ZIndex = 10000
	mainPanel.Parent = screengui
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = mainPanel
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = border
	panelStroke.Parent = mainPanel
	menuScale = Instance.new("UIScale")
	menuScale.Parent = mainPanel

	local function rounded(parent, radius)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius)
		corner.Parent = parent
	end

	local function outlined(parent)
		local stroke = Instance.new("UIStroke")
		stroke.Color = border
		stroke.Parent = parent
		return stroke
	end

	local function text(parent, value, size, colorValue)
		local item = Instance.new("TextLabel")
		item.BackgroundTransparency = 1
		item.Text = value
		item.TextSize = size
		item.Font = Enum.Font.Gotham
		item.TextColor3 = colorValue or textColor
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.ZIndex = 10001
		item.Parent = parent
		return item
	end

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, -70, 0, 74)
	header.BackgroundTransparency = 1
	header.Text = ""
	header.AutoButtonColor = false
	header.ZIndex = 10001
	header.Parent = mainPanel
	local title = text(header, "BNXYUNG7", 20)
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(22, 17)
	title.Size = UDim2.new(1, -22, 0, 27)
	local subtitle = text(header, hasTouch and "Dev: BNXYUNG7  /  CONTROLES MOVIL" or "Dev: BNXYUNG7  /  CONTROLES PC", 10, muted)
	subtitle.Position = UDim2.fromOffset(23, 46)
	subtitle.Size = UDim2.new(1, -23, 0, 16)

	local exit = Instance.new("TextButton")
	exit.Name = "exit"
	exit.Position = UDim2.new(1, -56, 0, 20)
	exit.Size = UDim2.fromOffset(34, 34)
	exit.BackgroundColor3 = surface
	exit.BorderSizePixel = 0
	exit.Text = "×"
	exit.TextSize = 23
	exit.Font = Enum.Font.Gotham
	exit.TextColor3 = muted
	exit.ZIndex = 10002
	exit.Parent = mainPanel
	rounded(exit, 8)
	track(exit.Activated:Connect(shutdown))

	local ENABLED = Instance.new("BoolValue")
	ENABLED.Name = "ENABLED"
	ENABLED.Value = enabledaim
	ENABLED.Parent = mainPanel
	local FOVOUTLINE = Instance.new("BoolValue")
	FOVOUTLINE.Name = "FOVOUTLINE"
	FOVOUTLINE.Value = fovoutline
	FOVOUTLINE.Parent = mainPanel
	local FOV = Instance.new("NumberValue")
	FOV.Name = "FOV"
	FOV.Value = fov
	FOV.Parent = mainPanel
	local WalkSpeed = Instance.new("NumberValue")
	WalkSpeed.Name = "WalkSpeed"
	WalkSpeed.Value = walkspeed
	WalkSpeed.Parent = mainPanel

	local function row(y, height)
		local frame = Instance.new("Frame")
		frame.Position = UDim2.fromOffset(20, y)
		frame.Size = UDim2.new(1, -40, 0, height)
		frame.BackgroundColor3 = surface
		frame.BorderSizePixel = 0
		frame.ZIndex = 10001
		frame.Parent = mainPanel
		rounded(frame, 10)
		outlined(frame)
		return frame
	end

	local function toggle(parent, titleText, description)
		local titleLabel = text(parent, titleText, 13)
		titleLabel.Position = UDim2.fromOffset(14, 8)
		titleLabel.Size = UDim2.new(1, -120, 0, 21)
		local descriptionLabel = text(parent, description, 10, muted)
		descriptionLabel.Position = UDim2.fromOffset(14, 32)
		descriptionLabel.Size = UDim2.new(1, -100, 0, 18)
		local state = text(parent, "ON", 9, accent)
		state.Position = UDim2.new(1, -76, 0, 8)
		state.Size = UDim2.fromOffset(62, 16)
		state.TextXAlignment = Enum.TextXAlignment.Right
		local pill = Instance.new("Frame")
		pill.Position = UDim2.new(1, -60, 0, 29)
		pill.Size = UDim2.fromOffset(46, 23)
		pill.BackgroundColor3 = accent
		pill.BorderSizePixel = 0
		pill.ZIndex = 10001
		pill.Parent = parent
		rounded(pill, 12)
		local knob = Instance.new("Frame")
		knob.Position = UDim2.fromOffset(26, 3)
		knob.Size = UDim2.fromOffset(17, 17)
		knob.BackgroundColor3 = textColor
		knob.BorderSizePixel = 0
		knob.ZIndex = 10002
		knob.Parent = pill
		rounded(knob, 9)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromScale(1, 1)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.ZIndex = 10003
		button.Parent = parent
		return state, pill, knob, button
	end

	local enabledState, enabledPill, enabledKnob, enabledButton = toggle(
		row(86, 58), "Sistema", "Conserva el comportamiento de tu código.")
	local outlineState, outlinePill, outlineKnob, outlineButton = toggle(
		row(152, 58), "Círculo FOV", "Muestra el radio alrededor del cursor.")

	local speedRow = row(220, 64)
	local speedTitle = text(speedRow, "WalkSpeed", 13)
	speedTitle.Position = UDim2.fromOffset(14, 9)
	speedTitle.Size = UDim2.fromOffset(150, 22)
	local speedHint = text(speedRow, "Valor entre 0 y 100", 10, muted)
	speedHint.Position = UDim2.fromOffset(14, 34)
	speedHint.Size = UDim2.fromOffset(170, 18)
	local WalkSpeedControl = Instance.new("TextBox")
	WalkSpeedControl.Name = "WalkSpeedControl"
	WalkSpeedControl.Position = UDim2.new(1, -128, 0, 15)
	WalkSpeedControl.Size = UDim2.fromOffset(112, 34)
	WalkSpeedControl.BackgroundColor3 = background
	WalkSpeedControl.BorderSizePixel = 0
	WalkSpeedControl.Text = tostring(walkspeed)
	WalkSpeedControl.TextSize = 14
	WalkSpeedControl.Font = Enum.Font.GothamBold
	WalkSpeedControl.TextColor3 = textColor
	WalkSpeedControl.ClearTextOnFocus = false
	WalkSpeedControl.KeyboardType = Enum.KeyboardType.Number
	WalkSpeedControl.ZIndex = 10002
	WalkSpeedControl.Parent = speedRow
	rounded(WalkSpeedControl, 7)

	local fovRow = row(294, 84)
	local fovTitle = text(fovRow, "Campo de visión (FOV)", 13)
	fovTitle.Position = UDim2.fromOffset(14, 10)
	fovTitle.Size = UDim2.new(1, -130, 0, 22)
	local fovValue = text(fovRow, tostring(fov) .. " px", 12, accent)
	fovValue.Font = Enum.Font.GothamBold
	fovValue.Position = UDim2.new(1, -104, 0, 10)
	fovValue.Size = UDim2.fromOffset(90, 22)
	fovValue.TextXAlignment = Enum.TextXAlignment.Right
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Position = UDim2.fromOffset(14, 54)
	sliderTrack.Size = UDim2.new(1, -28, 0, 4)
	sliderTrack.BackgroundColor3 = inactive
	sliderTrack.BorderSizePixel = 0
	sliderTrack.ZIndex = 10001
	sliderTrack.Parent = fovRow
	rounded(sliderTrack, 2)
	local sliderFill = Instance.new("Frame")
	sliderFill.BackgroundColor3 = accent
	sliderFill.BorderSizePixel = 0
	sliderFill.ZIndex = 10002
	sliderFill.Parent = sliderTrack
	rounded(sliderFill, 2)
	local sliderThumb = Instance.new("Frame")
	sliderThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderThumb.Size = UDim2.fromOffset(14, 14)
	sliderThumb.BackgroundColor3 = textColor
	sliderThumb.BorderSizePixel = 0
	sliderThumb.ZIndex = 10003
	sliderThumb.Parent = sliderTrack
	rounded(sliderThumb, 7)
	local sliderButton = Instance.new("TextButton")
	sliderButton.Position = UDim2.fromOffset(8, 39)
	sliderButton.Size = UDim2.new(1, -16, 0, 34)
	sliderButton.BackgroundTransparency = 1
	sliderButton.Text = ""
	sliderButton.ZIndex = 10004
	sliderButton.Parent = fovRow

	local hint = text(mainPanel, hasTouch
		and "– oculta el menu  ·  el icono lo abre de nuevo  ·  × destruye todo"
		or "P o –: ocultar / mostrar  ·  DELETE / ×: destruir todo", 10, muted)
	hint.Position = UDim2.new(0, 22, 1, -31)
	hint.Size = UDim2.new(1, -44, 0, 18)

	local mobileButton
	local buttonPlaced = false
	local function setMenuVisible(visible)
		mainPanel.Visible = visible
		activeSlider = nil
		panelDragging = false
		if mobileButton then
			mobileButton.Visible = not visible
			mobileButton.TextColor3 = accent
		end
	end

	local minimize = Instance.new("TextButton")
	minimize.Name = "minimize"
	minimize.Position = UDim2.new(1, -96, 0, 20)
	minimize.Size = UDim2.fromOffset(34, 34)
	minimize.BackgroundColor3 = surface
	minimize.BorderSizePixel = 0
	minimize.Text = "–"
	minimize.TextSize = 23
	minimize.Font = Enum.Font.Gotham
	minimize.TextColor3 = muted
	minimize.ZIndex = 10002
	minimize.Parent = mainPanel
	rounded(minimize, 8)
	track(minimize.Activated:Connect(function() setMenuVisible(false) end))

	if hasTouch then
		mobileButton = own(Instance.new("TextButton"))
		mobileButton.Name = "BNX_Menu"
		mobileButton.Size = UDim2.fromOffset(52, 52)
		mobileButton.BackgroundColor3 = background
		mobileButton.BorderSizePixel = 0
		mobileButton.Font = Enum.Font.GothamBold
		mobileButton.Text = "≡"
		mobileButton.TextSize = 21
		mobileButton.TextColor3 = accent
		mobileButton.AutoButtonColor = false
		mobileButton.ZIndex = 10005
		mobileButton.Parent = screengui
		rounded(mobileButton, 26)
		outlined(mobileButton)

		local buttonDragging = false
		local buttonMoved = false
		local buttonDragStart
		local buttonStart

		track(mobileButton.InputBegan:Connect(function(input)
			if cleaned or not isPointInput(input) then return end
			buttonDragging = true
			buttonMoved = false
			buttonDragStart = input.Position
			buttonStart = mobileButton.Position
		end))
		track(mobileButton.InputChanged:Connect(function(input)
			if cleaned or not buttonDragging or not isPointInput(input) then return end
			local delta = input.Position - buttonDragStart
			if delta.Magnitude > 8 then
				buttonMoved = true
			end
			mobileButton.Position = UDim2.new(buttonStart.X.Scale, buttonStart.X.Offset + delta.X,
				buttonStart.Y.Scale, buttonStart.Y.Offset + delta.Y)
		end))
		track(UIS.InputEnded:Connect(function(input)
			if isPointInput(input) then
				buttonDragging = false
			end
		end))
		track(mobileButton.Activated:Connect(function()
			if buttonMoved then return end
			setMenuVisible(not mainPanel.Visible)
		end))
		setMenuVisible(true)
	end

	local function resizeMenu()
		local camera = workspace.CurrentCamera
		if cleaned or not camera then return end
		local viewport = camera.ViewportSize
		if viewport.X <= 1 or viewport.Y <= 1 then return end
		local fit = math.min(1, math.max(1, viewport.X - 32) / panelSize.X,
			math.max(1, viewport.Y - 32) / panelSize.Y)
		menuScale.Scale = hasTouch and math.max(0.66, fit) or fit
		local size = panelSize * menuScale.Scale
		local x = math.clamp(mainPanel.Position.X.Offset, 16, math.max(16, viewport.X - size.X - 16))
		local y = math.clamp(mainPanel.Position.Y.Offset, 16, math.max(16, viewport.Y - size.Y - 16))
		mainPanel.Position = UDim2.fromOffset(x, y)
		if mobileButton then
			if not buttonPlaced then
				buttonPlaced = true
				mobileButton.Position = UDim2.fromOffset(size.X + 36, 24)
			end
			local bx = math.clamp(mobileButton.Position.X.Offset, 8, math.max(8, viewport.X - 60))
			local by = math.clamp(mobileButton.Position.Y.Offset, 8, math.max(8, viewport.Y - 60))
			mobileButton.Position = UDim2.fromOffset(bx, by)
		end
	end

	local function observeCamera()
		if cleaned then return end
		if viewportConnection then viewportConnection:Disconnect() end
		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeMenu))
			resizeMenu()
		end
	end

	local function refreshEnabled()
		enabledaim = ENABLED.Value
		enabledState.Text = ENABLED.Value and "ON" or "OFF"
		enabledState.TextColor3 = ENABLED.Value and accent or muted
		enabledPill.BackgroundColor3 = ENABLED.Value and accent or inactive
		enabledKnob.Position = UDim2.fromOffset(ENABLED.Value and 26 or 3, 3)
	end

	local function refreshOutline()
		fovoutline = FOVOUTLINE.Value
		outlineState.Text = FOVOUTLINE.Value and "ON" or "OFF"
		outlineState.TextColor3 = FOVOUTLINE.Value and accent or muted
		outlinePill.BackgroundColor3 = FOVOUTLINE.Value and accent or inactive
		outlineKnob.Position = UDim2.fromOffset(FOVOUTLINE.Value and 26 or 3, 3)
		if fovCircle then fovCircle.Visible = fovoutline end
		if fovDot then fovDot.Visible = fovoutline end
	end

	local function refreshFov()
		local ratio = (FOV.Value - 10) / 390
		fov = FOV.Value
		fovValue.Text = tostring(fov) .. " px"
		sliderFill.Size = UDim2.fromScale(ratio, 1)
		sliderThumb.Position = UDim2.fromScale(ratio, 0.5)
		drawCircle(fov, color)
	end

	track(ENABLED.Changed:Connect(refreshEnabled))
	track(FOVOUTLINE.Changed:Connect(refreshOutline))
	track(FOV.Changed:Connect(refreshFov))
	track(WalkSpeed.Changed:Connect(function(value: number)
		walkspeed = value
	end))
	track(enabledButton.Activated:Connect(function() ENABLED.Value = not ENABLED.Value end))
	track(outlineButton.Activated:Connect(function() FOVOUTLINE.Value = not FOVOUTLINE.Value end))
	track(WalkSpeedControl.FocusLost:Connect(function(enterpress)
		local value = tonumber(WalkSpeedControl.Text)
		if value and (enterpress or hasTouch) then
			WalkSpeed.Value = math.clamp(value, 0, 100)
		end
		WalkSpeedControl.Text = tostring(WalkSpeed.Value)
	end))

	local function setFovFromX(screenX)
		local ratio = math.clamp((screenX - sliderTrack.AbsolutePosition.X)
			/ math.max(sliderTrack.AbsoluteSize.X, 1), 0, 1)
		FOV.Value = math.floor(10 + ratio * 390 + 0.5)
	end

	track(sliderButton.InputBegan:Connect(function(input)
		if cleaned or not isPointInput(input) then return end
		panelDragging = false
		activeSlider = setFovFromX
		setFovFromX(input.Position.X)
	end))
	track(header.InputBegan:Connect(function(input)
		if cleaned or not isPointInput(input) then return end
		activeSlider = nil
		panelDragging = true
		panelDragStart = input.Position
		panelStart = mainPanel.Position
	end))
	track(UIS.InputChanged:Connect(function(input)
		if cleaned then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if activeSlider then
			activeSlider(input.Position.X)
		elseif panelDragging then
			local delta = input.Position - panelDragStart
			mainPanel.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X,
				panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		if isPointInput(input) then
			activeSlider = nil
			panelDragging = false
		end
	end))
	track(UIS.InputBegan:Connect(function(input, processed)
		if cleaned or processed or UIS:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.P then
			setMenuVisible(not mainPanel.Visible)
		elseif input.KeyCode == Enum.KeyCode.Delete then
			shutdown()
		end
	end))
	track(UIS.WindowFocusReleased:Connect(function()
		activeSlider = nil
		panelDragging = false
	end))
	track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(observeCamera))
	refreshEnabled()
	refreshOutline()
	refreshFov()
	observeCamera()
end

function gui()
	drawCircle(fov, CLR)
	drawDot(CLR)
	drawMain(CLR)
end

function main()
	if espying then
		for _, player in game.Players:GetPlayers() do
			if player == Localplayer then continue end
			if player.Character then
				esp(player.Character)
			else
				spawn(function()
					track(player.CharacterAdded:Once(esp))
				end)
			end
			track(player.CharacterAdded:Connect(esp))
		end

		track(game.Players.PlayerAdded:Connect(function(player)
			if player == Localplayer or cleaned then return end
			local char = player.Character or player.CharacterAdded:Wait()
			esp(player.Character)
			track(player.CharacterAdded:Connect(esp))
		end))
	else
		for _, player in game.Players:GetPlayers() do
			if player == Localplayer then continue end
			if player.Character then
				spawn(function()
					while not cleaned and player.Character.Humanoid.Health > 0 do
						temp_esp(player.Character)
						wait(spydown)
					end
				end)
			end
		end
	end

	gui()

	track(mouse.Move:Connect(function()
		if cleaned then return end
		local x = mouse.X
		local y = mouse.Y + offset

		for _, frame:Frame in screengui:GetChildren() do
			if frame.Name == "FovOutLine" or frame.Name == "FovOutLine-Dot" then
				frame.Position = UDim2.new(frame.Position.X.Scale, x, frame.Position.Y.Scale, y)
			end
		end
	end))
end

if enabledaim then
	main()
end
