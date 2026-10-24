local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Variables de estado
local menuOpen = true
local cursorUnlocked = false -- Estado del cursor libre con Alt
local flying = false
local noclip = false
local aimAssist = false
local triggerBot = false
local espEnabled = false
local autoFarmAI = false
local isAiming = false -- Se activa al mantener Clic Derecho
local flySpeed = 60
local aimSmoothness = 0.25 -- Suavidad del giro (0.05 = lento, 1 = instantáneo)
local aimMaxFov = 250 -- Radio de detección en píxeles
local farmDistance = 6 -- Distancia detrás del enemigo durante el Auto-Farm
local currentLockedTarget = nil -- Guarda el jugador enemigo fijado

local bodyVelocity, bodyGyro
local panelSize = UDim2.new(0, 250, 0, 465)

-- 1. CREACIÓN DE LA INTERFAZ (GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmoothAdminPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Botón Modal invisible (Libera el ratón en 1ra persona cuando está activo)
local modalUnlocker = Instance.new("TextButton")
modalUnlocker.Name = "CursorModalUnlocker"
modalUnlocker.Size = UDim2.new(0, 0, 0, 0)
modalUnlocker.BackgroundTransparency = 1
modalUnlocker.Text = ""
modalUnlocker.Modal = false
modalUnlocker.Visible = true
modalUnlocker.Parent = screenGui

-- Cursor visual personalizado (Se muestra cuando desbloqueas con Alt)
local customCursor = Instance.new("Frame")
customCursor.Name = "CustomQuickCursor"
customCursor.Size = UDim2.new(0, 10, 0, 10)
customCursor.AnchorPoint = Vector2.new(0.5, 0.5)
customCursor.BackgroundColor3 = Color3.fromRGB(75, 180, 255)
customCursor.BorderSizePixel = 0
customCursor.Visible = false
customCursor.ZIndex = 999
customCursor.Parent = screenGui

local cursorCorner = Instance.new("UICorner")
cursorCorner.CornerRadius = UDim.new(1, 0)
cursorCorner.Parent = customCursor

local cursorStroke = Instance.new("UIStroke")
cursorStroke.Color = Color3.fromRGB(255, 255, 255)
cursorStroke.Thickness = 1.5
cursorStroke.Parent = customCursor

-- Panel Principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = panelSize
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -232)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 75)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Título del panel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Panel de Control"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

-- Subtítulo informativo de atajos
local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, 0, 0, 16)
subTitle.Position = UDim2.new(0, 0, 0, 28)
subTitle.BackgroundTransparency = 1
subTitle.Text = "[Ctrl] Menú  |  [Alt] Liberar Cursor"
subTitle.TextColor3 = Color3.fromRGB(130, 145, 180)
subTitle.Font = Enum.Font.Gotham
subTitle.TextSize = 11
subTitle.Parent = mainFrame

-- Botón de Volar
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.84, 0, 0, 42)
flyButton.Position = UDim2.new(0.08, 0, 0, 52)
flyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
flyButton.Text = "Volar: DESACTIVADO"
flyButton.TextColor3 = Color3.fromRGB(200, 200, 210)
flyButton.Font = Enum.Font.GothamSemibold
flyButton.TextSize = 14
flyButton.AutoButtonColor = false
flyButton.Parent = mainFrame

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyButton

-- Botón de NoClip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.84, 0, 0, 42)
noclipButton.Position = UDim2.new(0.08, 0, 0, 104)
noclipButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
noclipButton.Text = "NoClip: DESACTIVADO"
noclipButton.TextColor3 = Color3.fromRGB(200, 200, 210)
noclipButton.Font = Enum.Font.GothamSemibold
noclipButton.TextSize = 14
noclipButton.AutoButtonColor = false
noclipButton.Parent = mainFrame

local noclipCorner = Instance.new("UICorner")
noclipCorner.CornerRadius = UDim.new(0, 8)
noclipCorner.Parent = noclipButton

-- Botón de Aim Assist (Seguimiento de Cámara)
local aimButton = Instance.new("TextButton")
aimButton.Size = UDim2.new(0.84, 0, 0, 42)
aimButton.Position = UDim2.new(0.08, 0, 0, 156)
aimButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
aimButton.Text = "Aim Look (Clic Der): OFF"
aimButton.TextColor3 = Color3.fromRGB(200, 200, 210)
aimButton.Font = Enum.Font.GothamSemibold
aimButton.TextSize = 14
aimButton.AutoButtonColor = false
aimButton.Parent = mainFrame

local aimCorner = Instance.new("UICorner")
aimCorner.CornerRadius = UDim.new(0, 8)
aimCorner.Parent = aimButton

-- Botón de TriggerBot
local triggerButton = Instance.new("TextButton")
triggerButton.Size = UDim2.new(0.84, 0, 0, 42)
triggerButton.Position = UDim2.new(0.08, 0, 0, 208)
triggerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
triggerButton.Text = "TriggerBot (Con Aim): OFF"
triggerButton.TextColor3 = Color3.fromRGB(200, 200, 210)
triggerButton.Font = Enum.Font.GothamSemibold
triggerButton.TextSize = 14
triggerButton.AutoButtonColor = false
triggerButton.Parent = mainFrame

local triggerCorner = Instance.new("UICorner")
triggerCorner.CornerRadius = UDim.new(0, 8)
triggerCorner.Parent = triggerButton

-- Botón de ESP (Solo Enemigos)
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0.84, 0, 0, 42)
espButton.Position = UDim2.new(0.08, 0, 0, 260)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
espButton.Text = "ESP Enemigos: OFF"
espButton.TextColor3 = Color3.fromRGB(200, 200, 210)
espButton.Font = Enum.Font.GothamSemibold
espButton.TextSize = 14
espButton.AutoButtonColor = false
espButton.Parent = mainFrame

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 8)
espCorner.Parent = espButton

-- Botón de IA Auto-Farm (Cazar Enemigos)
local farmButton = Instance.new("TextButton")
farmButton.Size = UDim2.new(0.84, 0, 0, 42)
farmButton.Position = UDim2.new(0.08, 0, 0, 312)
farmButton.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
farmButton.Text = "Auto-Farm IA: OFF"
farmButton.TextColor3 = Color3.fromRGB(200, 200, 210)
farmButton.Font = Enum.Font.GothamSemibold
farmButton.TextSize = 14
farmButton.AutoButtonColor = false
farmButton.Parent = mainFrame

local farmCorner = Instance.new("UICorner")
farmCorner.CornerRadius = UDim.new(0, 8)
farmCorner.Parent = farmButton

-- Contenedor de Velocidad
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.84, 0, 0, 20)
speedLabel.Position = UDim2.new(0.08, 0, 0, 365)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Velocidad de Vuelo"
speedLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.Parent = mainFrame

-- Botón Menos (-)
local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.22, 0, 0, 38)
minusBtn.Position = UDim2.new(0.08, 0, 0, 390)
minusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
minusBtn.Text = "-"
minusBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 18
minusBtn.Parent = mainFrame

local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(0, 8)
minusCorner.Parent = minusBtn

-- Caja de texto para Velocidad
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.36, 0, 0, 38)
speedBox.Position = UDim2.new(0.32, 0, 0, 390)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedBox.Text = tostring(flySpeed)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.GothamSemibold
speedBox.TextSize = 14
speedBox.ClearTextOnFocus = false
speedBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = speedBox

-- Botón Más (+)
local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.22, 0, 0, 38)
plusBtn.Position = UDim2.new(0.70, 0, 0, 390)
plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 18
plusBtn.Parent = mainFrame

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 8)
plusCorner.Parent = plusBtn

-- 2. SISTEMA DE CURSOR RÁPIDO CON TECLA ALT
local function setCursorUnlock(state)
	cursorUnlocked = state
	modalUnlocker.Modal = cursorUnlocked
	customCursor.Visible = cursorUnlocked

	if cursorUnlocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		subTitle.Text = "[Ctrl] Menú  |  Cursor: LIBRE (Alt)"
		subTitle.TextColor3 = Color3.fromRGB(100, 230, 140)
	else
		subTitle.Text = "[Ctrl] Menú  |  [Alt] Liberar Cursor"
		subTitle.TextColor3 = Color3.fromRGB(130, 145, 180)
	end
end

-- 3. SISTEMA DE ARRASTRE SUAVE (SMOOTH DRAG)
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		local targetPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = targetPos}):Play()
	end
end)

-- 4. LÓGICA DE VELOCIDAD
local function updateSpeed(newSpeed)
	flySpeed = math.clamp(newSpeed, 10, 500)
	speedBox.Text = tostring(flySpeed)
end

minusBtn.MouseButton1Click:Connect(function()
	updateSpeed(flySpeed - 10)
end)

plusBtn.MouseButton1Click:Connect(function()
	updateSpeed(flySpeed + 10)
end)

speedBox.FocusLost:Connect(function()
	local val = tonumber(speedBox.Text)
	if val then
		updateSpeed(val)
	else
		speedBox.Text = tostring(flySpeed)
	end
end)

-- 5. LÓGICA DE NOCLIP
local function toggleNoClip()
	noclip = not noclip
	if noclip then
		TweenService:Create(noclipButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(75, 130, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		noclipButton.Text = "NoClip: ACTIVADO"
	else
		TweenService:Create(noclipButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		noclipButton.Text = "NoClip: DESACTIVADO"
		
		if player.Character then
			for _, part in ipairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

noclipButton.MouseButton1Click:Connect(toggleNoClip)

RunService.Stepped:Connect(function()
	if (noclip or autoFarmAI) and player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
end)

-- 6. VERIFICACIÓN DE ENEMIGOS (TEAM CHECK)
local function isEnemy(otherPlayer)
	if not otherPlayer or otherPlayer == player then
		return false
	end
	if player.Neutral or otherPlayer.Neutral or not player.Team or not otherPlayer.Team then
		return true
	end
	return otherPlayer.Team ~= player.Team
end

-- 7. LÓGICA DE ESP (SOLO ENEMIGOS)
local function clearAllESP()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			local existingHighlight = otherPlayer.Character:FindFirstChild("EnemyESPHighlight")
			if existingHighlight then
				existingHighlight:Destroy()
			end
		end
	end
end

local function updateESP()
	if not espEnabled then return end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local char = otherPlayer.Character
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local isTargetEnemy = isEnemy(otherPlayer) and humanoid and humanoid.Health > 0
			local highlight = char:FindFirstChild("EnemyESPHighlight")

			if isTargetEnemy then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "EnemyESPHighlight"
					highlight.Adornee = char
					highlight.FillColor = Color3.fromRGB(255, 60, 60)
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
					highlight.FillTransparency = 0.55
					highlight.OutlineTransparency = 0.1
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = char
				end
			else
				if highlight then
					highlight:Destroy()
				end
			end
		end
	end
end

local function toggleESP()
	espEnabled = not espEnabled
	if espEnabled then
		TweenService:Create(espButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(75, 130, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		espButton.Text = "ESP Enemigos: ON"
		updateESP()
	else
		TweenService:Create(espButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		espButton.Text = "ESP Enemigos: OFF"
		clearAllESP()
	end
end

espButton.MouseButton1Click:Connect(toggleESP)

-- 8. LÓGICA DE AIM ASSIST / SEGUIMIENTO DE CÁMARA
local function toggleAimAssist()
	aimAssist = not aimAssist
	if aimAssist then
		TweenService:Create(aimButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(75, 130, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		aimButton.Text = "Aim Look (Clic Der): ON"
	else
		TweenService:Create(aimButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		aimButton.Text = "Aim Look (Clic Der): OFF"
		currentLockedTarget = nil
	end
end

aimButton.MouseButton1Click:Connect(toggleAimAssist)

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
		currentLockedTarget = nil
	end
end)

local function getClosestEnemyOnScreen()
	local closestHead = nil
	local closestEnemyPlayer = nil
	local shortestDistance = aimMaxFov
	local mousePos = UserInputService:GetMouseLocation()

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if isEnemy(otherPlayer) and otherPlayer.Character then
			local targetHead = otherPlayer.Character:FindFirstChild("Head")
			local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")

			if targetHead and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = camera:WorldToViewportPoint(targetHead.Position)
				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distance = (mousePos - screenVector).Magnitude

					if distance < shortestDistance then
						shortestDistance = distance
						closestHead = targetHead
						closestEnemyPlayer = otherPlayer
					end
				end
			end
		end
	end

	return closestHead, closestEnemyPlayer
end

-- 9. LÓGICA DE TRIGGERBOT
local function toggleTriggerBot()
	triggerBot = not triggerBot
	if triggerBot then
		TweenService:Create(triggerButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(75, 130, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		triggerButton.Text = "TriggerBot (Con Aim): ON"
	else
		TweenService:Create(triggerButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		triggerButton.Text = "TriggerBot (Con Aim): OFF"
	end
end

triggerButton.MouseButton1Click:Connect(toggleTriggerBot)

local function fireEquippedWeapon()
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local equippedTool = player.Character:FindFirstChildOfClass("Tool")

	if not equippedTool and humanoid then
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			local firstTool = backpack:FindFirstChildOfClass("Tool")
			if firstTool then
				humanoid:EquipTool(firstTool)
				equippedTool = firstTool
			end
		end
	end

	if equippedTool then
		equippedTool:Activate()
	elseif mouse1click then
		mouse1click()
	end
end

local function fireInstantTriggerBot()
	if not triggerBot or not aimAssist or not isAiming or not currentLockedTarget then
		return
	end
	if not player.Character then return end

	local targetPart = mouse.Target
	if targetPart and targetPart.Parent then
		local model = targetPart:FindFirstAncestorOfClass("Model")
		if model then
			local hoveredPlayer = Players:GetPlayerFromCharacter(model)
			local humanoid = model:FindFirstChildOfClass("Humanoid")

			if hoveredPlayer and hoveredPlayer == currentLockedTarget and isEnemy(hoveredPlayer) and humanoid and humanoid.Health > 0 then
				fireEquippedWeapon()
			end
		end
	end
end

-- 10. LÓGICA DE IA AUTO-FARM
local function toggleAutoFarmAI()
	autoFarmAI = not autoFarmAI
	if autoFarmAI then
		TweenService:Create(farmButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(235, 65, 65),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		farmButton.Text = "Auto-Farm IA: ON"
	else
		TweenService:Create(farmButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		farmButton.Text = "Auto-Farm IA: OFF"
		
		if player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end

farmButton.MouseButton1Click:Connect(toggleAutoFarmAI)

local function getNearestAliveEnemyInWorld()
	local myChar = player.Character
	if not myChar then return nil end
	local myHrp = myChar:FindFirstChild("HumanoidRootPart")
	if not myHrp then return nil end

	local bestTargetChar = nil
	local shortestWorldDist = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if isEnemy(otherPlayer) and otherPlayer.Character then
			local enemyChar = otherPlayer.Character
			local enemyHrp = enemyChar:FindFirstChild("HumanoidRootPart")
			local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
			local forceField = enemyChar:FindFirstChildOfClass("ForceField")

			if enemyHrp and enemyHum and enemyHum.Health > 0 and not forceField then
				local dist = (myHrp.Position - enemyHrp.Position).Magnitude
				if dist < shortestWorldDist then
					shortestWorldDist = dist
					bestTargetChar = enemyChar
				end
			end
		end
	end

	return bestTargetChar
end

local function updateAutoFarmAI()
	local myChar = player.Character
	if not myChar then return end
	local myHrp = myChar:FindFirstChild("HumanoidRootPart")
	local myHum = myChar:FindFirstChildOfClass("Humanoid")
	if not myHrp or not myHum or myHum.Health <= 0 then return end

	local targetEnemyChar = getNearestAliveEnemyInWorld()
	if targetEnemyChar then
		local enemyHrp = targetEnemyChar:FindFirstChild("HumanoidRootPart")
		local enemyHead = targetEnemyChar:FindFirstChild("Head") or enemyHrp

		if enemyHrp and enemyHead then
			local behindPosition = enemyHrp.Position - (enemyHrp.CFrame.LookVector * farmDistance) + Vector3.new(0, 2, 0)
			myHrp.CFrame = CFrame.new(behindPosition, enemyHead.Position)
			myHrp.AssemblyLinearVelocity = Vector3.zero

			camera.CFrame = CFrame.new(camera.CFrame.Position, enemyHead.Position)
			fireEquippedWeapon()
		end
	end
end

-- 11. LÓGICA DE VUELO
local function toggleFly()
	flying = not flying
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	if flying then
		TweenService:Create(flyButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(75, 130, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		flyButton.Text = "Volar: ACTIVADO"

		humanoid.PlatformStand = true

		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.Parent = hrp

		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		bodyGyro.P = 9000
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.Parent = hrp
	else
		TweenService:Create(flyButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 52),
			TextColor3 = Color3.fromRGB(200, 200, 210)
		}):Play()
		flyButton.Text = "Volar: DESACTIVADO"

		humanoid.PlatformStand = false
		if bodyVelocity then bodyVelocity:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end
	end
end

flyButton.MouseButton1Click:Connect(toggleFly)

-- 12. BUCLE PRINCIPAL (CURSOR ALT + AUTO-FARM + AIM + TRIGGER + ESP + VUELO)
local currentVelocity = Vector3.zero
RunService.RenderStepped:Connect(function()
	-- 0. Actualizar posición del cursor rápido si está activo con Alt
	if cursorUnlocked then
		local mouseLocation = UserInputService:GetMouseLocation()
		customCursor.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- 1. IA Auto-Farm
	if autoFarmAI then
		updateAutoFarmAI()
	elseif aimAssist and isAiming and not cursorUnlocked then
		-- 2. Aim Look Manual (Se pausa si tienes el cursor libre para hacer clic en el panel)
		local targetHead, enemyPlayer = getClosestEnemyOnScreen()
		currentLockedTarget = enemyPlayer
		if targetHead then
			local targetCFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
			camera.CFrame = camera.CFrame:Lerp(targetCFrame, aimSmoothness)
		end
	else
		currentLockedTarget = nil
	end

	-- 3. TriggerBot sin delay
	if triggerBot and not autoFarmAI and not cursorUnlocked then
		fireInstantTriggerBot()
	end

	-- 4. ESP (Solo enemigos vivos)
	if espEnabled then
		updateESP()
	end

	-- 5. Vuelo Manual
	if flying and not autoFarmAI and player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and bodyVelocity and bodyGyro then
			local moveDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end

			if moveDir.Magnitude > 0 then
				moveDir = moveDir.Unit * flySpeed
			end

			currentVelocity = currentVelocity:Lerp(moveDir, 0.15)
			bodyVelocity.Velocity = currentVelocity
			bodyGyro.CFrame = camera.CFrame
		end
	end
end)

-- 13. ATAJOS DE TECLADO: CONTROL (ABRIR/CERRAR) Y ALT (LIBERAR CURSOR)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Tecla ALT para activar/desactivar el cursor libre al instante
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		setCursorUnlock(not cursorUnlocked)
		return
	end

	if gameProcessed then return end

	-- Tecla CONTROL para abrir/cerrar el menú con animación Smooth
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		menuOpen = not menuOpen
		if menuOpen then
			mainFrame.Visible = true
			TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = panelSize
			}):Play()
		else
			-- Si cierras el menú, también vuelve a bloquear el cursor para seguir jugando cómodo
			if cursorUnlocked then
				setCursorUnlock(false)
			end
			local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 250, 0, 0)
			})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				if not menuOpen then
					mainFrame.Visible = false
				end
			end)
		end
	end
end)
