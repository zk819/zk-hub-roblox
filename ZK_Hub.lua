-- ============================================
-- ZK HUB 🎯 - AIM ASSIST + ESP + HITBOX
-- DESIGN EXCLUSIVO - v3.0.0 (FINAL)
-- RAINBOW FOV | FPS COUNTER | FPS BOOSTER
-- ============================================

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========== CORES ==========
local Colors = {
    Background = Color3.fromRGB(10, 10, 10),
    Surface = Color3.fromRGB(26, 26, 26),
    Primary = Color3.fromRGB(0, 102, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 200),
    Success = Color3.fromRGB(0, 200, 0),
    Danger = Color3.fromRGB(255, 70, 70),
    Inactive = Color3.fromRGB(60, 60, 70)
}

-- ========== CONFIGURAÇÕES ==========
local Config = {
    AimbotActive = true,
    AimbotSmooth = 18,
    AimbotTarget = "HEAD",
    AimbotFOV = 150,
    ESPActive = false,
    ShowHitbox = false,
    Notifications = true,
    FPSCounter = false,
    FPSBooster = false
}

-- ========== VARIÁVEIS ==========
local FOVCircle = nil
local UI = nil
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local ESPDrawings = {}
local HitboxDrawings = {}
local CurrentTarget = nil

-- ========== SUPORTE A DRAWING ==========
local DrawingSupported = pcall(Drawing.new, "Square")

-- ========== NOTIFICAÇÃO ==========
local function Notify(msg)
    if Config.Notifications then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "ZK HUB 🎯",
                Text = msg,
                Duration = 1.5
            })
        end)
    end
end

-- ========== RAINBOW FOV ==========
local hue = 0
local function UpdateFOVCircle()
    if not Config.AimbotActive then
        if FOVCircle then FOVCircle:Destroy(); FOVCircle = nil end
        return
    end

    if not FOVCircle then
        FOVCircle = Instance.new("ScreenGui")
        FOVCircle.Name = "ZKFOV"
        FOVCircle.Parent = CoreGui
        FOVCircle.ResetOnSpawn = false
        FOVCircle.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        FOVCircle.DisplayOrder = 999

        local circle = Instance.new("Frame")
        circle.Name = "Circle"
        circle.BackgroundTransparency = 1
        circle.BorderSizePixel = 0
        circle.Parent = FOVCircle

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        stroke.Parent = circle
    end

    local circle = FOVCircle:FindFirstChild("Circle")
    if circle then
        hue = (hue + 0.005) % 1
        local rainbow = Color3.fromHSV(hue, 1, 1)
        circle.UIStroke.Color = rainbow

        local size = Config.AimbotFOV * 2
        circle.Size = UDim2.new(0, size, 0, size)
        circle.Position = UDim2.new(0.5, -Config.AimbotFOV, 0.5, -Config.AimbotFOV)
    end
end
RunService.RenderStepped:Connect(UpdateFOVCircle)

-- ========== FPS COUNTER ==========
local FPSText = Drawing.new("Text")
FPSText.Visible = false
FPSText.Color = Color3.new(0, 1, 0)
FPSText.Size = 18
FPSText.Center = false
FPSText.Outline = true
FPSText.Position = Vector2.new(10, 10)
FPSText.Text = "FPS: 60"

local start = nil
local frameCount = 0
local fps = 60

RunService.RenderStepped:Connect(function()
    if Config.FPSCounter then
        FPSText.Visible = true
        frameCount = frameCount + 1

        if not start then start = tick() end
        local elapsed = tick() - start
        if elapsed >= 0.5 then
            fps = math.floor(frameCount / elapsed + 0.5)
            start = tick()
            frameCount = 0
        end

        FPSText.Text = "FPS: " .. fps
        if fps >= 60 then
            FPSText.Color = Color3.new(0, 1, 0)
        elseif fps >= 30 then
            FPSText.Color = Color3.new(1, 1, 0)
        else
            FPSText.Color = Color3.new(1, 0, 0)
        end
    else
        FPSText.Visible = false
    end
end)

-- ========== FPS BOOSTER ==========
local OriginalSettings = {}

local function ApplyFPSBooster(enable)
    if enable then
        if next(OriginalSettings) == nil then
            OriginalSettings = {
                GlobalShadows = Workspace.CurrentCamera.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                DecalsEnabled = Workspace.CurrentCamera.DecalsEnabled,
                TopbarTransparency = playerGui:GetTopbarTransparency(),
            }
        end

        Workspace.CurrentCamera.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Workspace.CurrentCamera.DecalsEnabled = false
        playerGui:SetTopbarTransparency(1)

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end

        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") and (obj.Position - Camera.CFrame.Position).Magnitude > 100 then
                    obj.Enabled = false
                end
            end
        end)
    else
        if OriginalSettings.GlobalShadows ~= nil then
            Workspace.CurrentCamera.GlobalShadows = OriginalSettings.GlobalShadows
            Lighting.FogEnd = OriginalSettings.FogEnd
            Workspace.CurrentCamera.DecalsEnabled = OriginalSettings.DecalsEnabled
            playerGui:SetTopbarTransparency(OriginalSettings.TopbarTransparency)
        end

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = true
            end
        end
    end
end

-- ========== DETECTAR INIMIGOS ==========
local function IsEnemy(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    if not model:FindFirstChild("Humanoid") or not model:FindFirstChild("HumanoidRootPart") then return false end

    local humanoid = model.Humanoid
    if humanoid.Health <= 0 then return false end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if player == LocalPlayer then return false end

        if LocalPlayer.TeamColor ~= BrickColor.new("White") and player.TeamColor ~= BrickColor.new("White") then
            return LocalPlayer.TeamColor ~= player.TeamColor
        end

        local myTeam = LocalPlayer.Team
        local theirTeam = player.Team
        if myTeam and theirTeam then
            return myTeam ~= theirTeam
        end

        return true
    end

    local name = model.Name:lower()
    if name:find("civil") or name:find("civilian") or name:find("npc") or name:find("civ") then
        return false
    end
    return true
end

local function GetEnemies()
    local enemies = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and IsEnemy(obj) then
            table.insert(enemies, {
                Model = obj,
                Root = obj.HumanoidRootPart,
                Humanoid = obj.Humanoid
            })
        end
    end
    return enemies
end

-- ========== AIM ASSIST ==========
local function GetBestTarget()
    if not Config.AimbotActive then return nil end

    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestScore = Config.AimbotFOV + 1
    local enemies = GetEnemies()

    for _, enemy in ipairs(enemies) do
        local targetPart = enemy.Root
        if Config.AimbotTarget == "HEAD" then
            targetPart = enemy.Model:FindFirstChild("Head") or enemy.Root
        elseif Config.AimbotTarget == "TORSO" then
            targetPart = enemy.Model:FindFirstChild("UpperTorso") or enemy.Model:FindFirstChild("Torso") or enemy.Root
        end

        if targetPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distFromCenter <= Config.AimbotFOV and distFromCenter < bestScore then
                    bestScore = distFromCenter
                    bestTarget = { Part = targetPart, Position = targetPart.Position, Model = enemy.Model }
                end
            end
        end
    end
    return bestTarget
end

local function AimAtTarget(target)
    if not target then return end
    local cameraPos = Camera.CFrame.Position
    local targetPos = target.Position
    local direction = (targetPos - cameraPos).Unit

    local smooth = Config.AimbotSmooth / 100
    local currentLook = Camera.CFrame.LookVector
    local newLook = currentLook:Lerp(direction, smooth)

    pcall(function()
        Camera.CFrame = CFrame.lookAt(cameraPos, cameraPos + newLook)
    end)
end

RunService.RenderStepped:Connect(function()
    if Config.AimbotActive then
        local target = GetBestTarget()
        CurrentTarget = target
        if target then
            AimAtTarget(target)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
end)

-- ========== ESP ==========
local function ClearESP()
    for _, drawing in pairs(ESPDrawings) do
        for _, d in pairs(drawing) do
            pcall(function() d:Remove() end)
        end
    end
    ESPDrawings = {}

    for _, d in pairs(HitboxDrawings) do
        pcall(function() d:Remove() end)
    end
    HitboxDrawings = {}
end

local function UpdateESP()
    if not Config.ESPActive or not DrawingSupported then
        ClearESP()
        return
    end

    local enemies = GetEnemies()
    local currentModels = {}
    for _, enemy in ipairs(enemies) do
        currentModels[enemy.Model] = true
    end

    for model, drawing in pairs(ESPDrawings) do
        if not currentModels[model] then
            for _, d in pairs(drawing) do
                pcall(function() d:Remove() end)
            end
            ESPDrawings[model] = nil
        end
    end

    for _, enemy in ipairs(enemies) do
        local model = enemy.Model
        local root = enemy.Root
        local humanoid = enemy.Humanoid
        local head = model:FindFirstChild("Head") or root

        local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

        if rootVis or headVis then
            local screenPos = Vector2.new(rootPos.X, rootPos.Y)
            local boxHeight = math.abs(rootPos.Y - headPos.Y) * 1.8
            local boxWidth = boxHeight * 0.6

            if not ESPDrawings[model] then
                local box = Drawing.new("Square")
                box.Visible = false
                box.Color = Color3.new(1, 0, 0)
                box.Thickness = 1
                box.Filled = false

                local nameLabel = Drawing.new("Text")
                nameLabel.Visible = false
                nameLabel.Color = Color3.new(1, 1, 1)
                nameLabel.Size = 16
                nameLabel.Center = true
                nameLabel.Outline = true

                local healthLabel = Drawing.new("Text")
                healthLabel.Visible = false
                healthLabel.Color = Color3.new(0, 1, 0)
                healthLabel.Size = 14
                healthLabel.Center = true
                healthLabel.Outline = true

                local distLabel = Drawing.new("Text")
                distLabel.Visible = false
                distLabel.Color = Color3.new(0.8, 0.8, 0.8)
                distLabel.Size = 14
                distLabel.Center = true
                distLabel.Outline = true

                ESPDrawings[model] = {
                    Box = box,
                    Name = nameLabel,
                    Health = healthLabel,
                    Dist = distLabel
                }
            end

            local esp = ESPDrawings[model]
            local box = esp.Box
            local nameLabel = esp.Name
            local healthLabel = esp.Health
            local distLabel = esp.Dist

            box.Visible = true
            box.Position = Vector2.new(screenPos.X - boxWidth/2, screenPos.Y - boxHeight/2)
            box.Size = Vector2.new(boxWidth, boxHeight)

            nameLabel.Visible = true
            nameLabel.Text = model.Name
            nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 16)

            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local healthPercent = health / maxHealth
            local healthColor = Color3.new(1 - healthPercent, healthPercent, 0)
            healthLabel.Visible = true
            healthLabel.Text = string.format("%.0f/%.0f", health, maxHealth)
            healthLabel.Color = healthColor
            healthLabel.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 2)

            local distance = (Camera.CFrame.Position - root.Position).Magnitude
            distLabel.Visible = true
            distLabel.Text = string.format("%.0fm", distance)
            distLabel.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight/2 + 2)
        else
            if ESPDrawings[model] then
                for _, d in pairs(ESPDrawings[model]) do
                    d.Visible = false
                end
            end
        end
    end
end

-- ========== HITBOX ==========
local pulse = 0
local pulseDir = 1

local function UpdateHitbox()
    if not Config.ShowHitbox or not DrawingSupported then
        for _, d in pairs(HitboxDrawings) do
            pcall(function() d:Remove() end)
        end
        HitboxDrawings = {}
        return
    end

    pulse = pulse + pulseDir * 0.05
    if pulse > 1 then pulseDir = -1; pulse = 1
    elseif pulse < 0 then pulseDir = 1; pulse = 0 end

    for model, circle in pairs(HitboxDrawings) do
        if model ~= (CurrentTarget and CurrentTarget.Model) then
            pcall(function() circle:Remove() end)
            HitboxDrawings[model] = nil
        end
    end

    if CurrentTarget and CurrentTarget.Part then
        local model = CurrentTarget.Model
        local part = CurrentTarget.Part
        local pos, vis = Camera:WorldToViewportPoint(part.Position)
        if vis then
            if not HitboxDrawings[model] then
                local circle = Drawing.new("Circle")
                circle.Visible = false
                circle.Color = Colors.Primary
                circle.Thickness = 2
                circle.NumSides = 20
                circle.Filled = false
                circle.Radius = 8
                HitboxDrawings[model] = circle
            end

            local circle = HitboxDrawings[model]
            circle.Visible = true
            circle.Position = Vector2.new(pos.X, pos.Y)
            circle.Color = Color3.new(0.3 + pulse * 0.7, 0.5 + pulse * 0.5, 1)
            circle.Radius = 8 + pulse * 2
        else
            if HitboxDrawings[model] then
                HitboxDrawings[model].Visible = false
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateHitbox()
end)

-- ========== FUNÇÕES AUXILIARES DA UI ==========
local function createToggle(parent, y, text, var, default)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 45)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 16
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 70, 0, 30)
    btn.Position = UDim2.new(1, -70, 0.5, -15)
    btn.TextColor3 = Colors.Text
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    local function updateToggleVisual()
        btn.BackgroundColor3 = Config[var] and Colors.Success or Colors.Inactive
        btn.Text = Config[var] and "ON" or "OFF"
    end

    updateToggleVisual()

    btn.MouseButton1Click:Connect(function()
        Config[var] = not Config[var]
        updateToggleVisual()
        Notify(text .. " " .. (Config[var] and "ON" or "OFF"))

        if var == "FPSBooster" then
            ApplyFPSBooster(Config[var])
        end
    end)

    return 50
end

local function createSlider(parent, y, text, var, min, max, default, suffix)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 65)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.6, 0, 0, 25)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 16
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.4, -10, 0, 25)
    valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default) .. (suffix or "")
    valLbl.TextColor3 = Colors.Primary
    valLbl.TextSize = 18
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", frame)
    bg.Size = UDim2.new(1, 0, 0, 20)
    bg.Position = UDim2.new(0, 0, 0, 30)
    bg.BackgroundColor3 = Colors.Inactive
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 10)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Primary
    fill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 10)

    local sliderBtn = Instance.new("TextButton", bg)
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""

    local dragging = false
    local function update(input)
        local pos = input.Position
        local absPos = bg.AbsolutePosition
        local absSize = bg.AbsoluteSize.X
        local rel = math.clamp(pos.X - absPos.X, 0, absSize)
        local percent = rel / absSize
        local value = math.floor(min + (max - min) * percent)
        Config[var] = value
        valLbl.Text = tostring(value) .. (suffix or "")
        fill.Size = UDim2.new(percent, 0, 1, 0)
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    sliderBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    slide
