-- Visuals.lua
local Visuals = {}

-- ESP Implementation using BillboardGui and Highlight
local ESP = {}
ESP.Objects = {}

local function CreateESP(player)
    if player == Core.Players.LocalPlayer then return end

    local esp = {
        BillboardGui = nil, -- For text labels (Name, Distance, Health, Weapon)
        Highlight = nil,    -- For box
        Labels = {
            Name = nil,
            Distance = nil,
            Health = nil,
            Weapon = nil
        }
        -- Skeleton ESP is disabled in this version due to Drawing library removal
    }

    -- Create BillboardGui for text labels
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_" .. player.Name
    billboardGui.Size = UDim2.new(0, 200, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above the player's head
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 2000
    billboardGui.Enabled = false
    esp.BillboardGui = billboardGui

    -- Create labels for Name, Distance, Health, and Weapon
    local function createLabel(name, offsetY, size)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Size = UDim2.new(1, 0, 0, size)
        label.Position = UDim2.new(0, 0, 0, offsetY)
        label.BackgroundTransparency = 1
        label.TextColor3 = Core.Settings.Visuals.EnemyColor
        label.TextSize = size
        label.Font = Enum.Font.SourceSansBold
        label.Text = ""
        label.Visible = false
        label.Parent = billboardGui
        return label
    end

    esp.Labels.Name = createLabel("Name", 0, 16)
    esp.Labels.Distance = createLabel("Distance", 20, 14)
    esp.Labels.Health = createLabel("Health", 40, 14)
    esp.Labels.Weapon = createLabel("Weapon", 60, 14)

    -- Create Highlight for box
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPBox_" .. player.Name
    highlight.FillColor = Core.Settings.Visuals.EnemyColor
    highlight.OutlineColor = Core.OUTLINE_COLOR
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    esp.Highlight = highlight

    -- Parent BillboardGui and Highlight to player character when available
    if player.Character then
        billboardGui.Adornee = player.Character:FindFirstChild("Head")
        highlight.Adornee = player.Character
    end

    ESP.Objects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(ESP.Objects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            -- Update Adornee for BillboardGui and Highlight
            if head and esp.BillboardGui.Adornee ~= head then
                esp.BillboardGui.Adornee = head
            end
            if esp.Highlight.Adornee ~= player.Character then
                esp.Highlight.Adornee = player.Character
            end

            if Core.Settings.Visuals.ESPEnabled then
                local isTeam = Core.Settings.Visuals.TeamCheck and player.Team == Core.Players.LocalPlayer.Team
                local color = isTeam and Core.Settings.Visuals.TeamColor or Core.Settings.Visuals.EnemyColor

                -- Update BillboardGui visibility
                esp.BillboardGui.Enabled = true
                esp.BillboardGui.Parent = Core.Players.LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("StarterGui")

                -- Update Highlight visibility
                esp.Highlight.Enabled = Core.Settings.Visuals.Box
                esp.Highlight.Parent = player.Character
                esp.Highlight.FillColor = color

                if Core.Settings.Visuals.Name then
                    esp.Labels.Name.Text = player.Name
                    esp.Labels.Name.TextColor3 = color
                    esp.Labels.Name.Visible = true
                else
                    esp.Labels.Name.Visible = false
                end

                if Core.Settings.Visuals.Distance then
                    local distance = (Core.Players.LocalPlayer.Character and Core.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (Core.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                    esp.Labels.Distance.Text = string.format("%.0f studs", distance)
                    esp.Labels.Distance.TextColor3 = color
                    esp.Labels.Distance.Visible = true
                else
                    esp.Labels.Distance.Visible = false
                end

                if Core.Settings.Visuals.Health and humanoid then
                    esp.Labels.Health.Text = string.format("%d HP", humanoid.Health)
                    esp.Labels.Health.TextColor3 = color
                    esp.Labels.Health.Visible = true
                else
                    esp.Labels.Health.Visible = false
                end

                if Core.Settings.Visuals.Weapon then
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    esp.Labels.Weapon.Text = tool and tool.Name or "None"
                    esp.Labels.Weapon.TextColor3 = color
                    esp.Labels.Weapon.Visible = true
                else
                    esp.Labels.Weapon.Visible = false
                end

                -- Skeleton ESP is disabled in this version
            else
                esp.BillboardGui.Enabled = false
                esp.Highlight.Enabled = false
            end
        else
            esp.BillboardGui.Enabled = false
            esp.Highlight.Enabled = false
        end
    end
end

local function ScanPlayers()
    for _, player in pairs(Core.Players:GetPlayers()) do
        if not ESP.Objects[player] and player ~= Core.Players.LocalPlayer then
            CreateESP(player)
        end
    end
end

-- Chams Implementation
local ChamsHighlights = {}
local function ApplyChams(player)
    if player == Core.Players.LocalPlayer or not Core.Settings.Visuals.Chams then return end
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (Core.Camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude
        if distance > 2000 then return end
        
        local highlight = ChamsHighlights[player]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = player.Character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            ChamsHighlights[player] = highlight
        end
        
        local isVisible = #Core.Camera:GetPartsObscuringTarget({player.Character[Core.Settings.Aimbot.TargetPart].Position}, {Core.Players.LocalPlayer.Character or {}, player.Character}) == 0
        highlight.FillColor = isVisible and Core.Settings.Visuals.ChamsVisibleColor or Core.Settings.Visuals.ChamsOccludedColor
        highlight.FillTransparency = Core.Settings.Visuals.ChamsTransparency
        highlight.OutlineColor = Core.OUTLINE_COLOR
        highlight.OutlineTransparency = 0
        highlight.Enabled = true
    end
end

local function ResetChams(player)
    if player == Core.Players.LocalPlayer then return end
    
    local highlight = ChamsHighlights[player]
    if highlight then
        highlight:Destroy()
        ChamsHighlights[player] = nil
    end
end

-- Hand Chams Implementation
local function ApplyHandChams(character)
    if not Core.Settings.Visuals.HandChams or not character then return end
    
    local arms = {}
    local weaponParts = {}
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("MeshPart") and (part.Name:match("Arm") or part.Name:match("Hand")) then
            table.insert(arms, part)
        end
    end
    
    local weapon = character:FindFirstChildOfClass("Tool")
    if weapon then
        for _, part in pairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(weaponParts, part)
            end
        end
    end
    
    for _, part in pairs(arms) do
        part.Color = Core.Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[Core.Settings.Visuals.HandChamsMaterial]
        part.Transparency = Core.Settings.Visuals.HandChamsTransparency
    end
    
    for _, part in pairs(weaponParts) do
        part.Color = Core.Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[Core.Settings.Visuals.HandChamsMaterial]
        part.Transparency = Core.Settings.Visuals.HandChamsTransparency
    end
end

local function ResetHandChams(character)
    if not character then return end
    
    local arms = {}
    local weaponParts = {}
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("MeshPart") and (part.Name:match("Arm") or part.Name:match("Hand")) then
            table.insert(arms, part)
        end
    end
    
    local weapon = character:FindFirstChildOfClass("Tool")
    if weapon then
        for _, part in pairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(weaponParts, part)
            end
        end
    end
    
    for _, part in pairs(arms) do
        part.Color = Color3.fromRGB(255, 255, 255)
        part.Material = Enum.Material.SmoothPlastic
        part.Transparency = 0
    end
    
    for _, part in pairs(weaponParts) do
        part.Color = Color3.fromRGB(255, 255, 255)
        part.Material = Enum.Material.SmoothPlastic
        part.Transparency = 0
    end
end

local function UpdateHandChams()
    if not Core.Players.LocalPlayer.Character then return end
    if Core.Settings.Visuals.HandChams then
        ApplyHandChams(Core.Players.LocalPlayer.Character)
    else
        ResetHandChams(Core.Players.LocalPlayer.Character)
    end
end

-- Bullet Tracers Implementation
local function CreateBulletTracer(startPos, endPos)
    if not Core.Settings.Weapon.BulletTracers or Core.ActiveTracers >= Core.MaxTracers then return end
    Core.ActiveTracers = Core.ActiveTracers + 1

    local beamPart = Instance.new("Part")
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Size = Vector3.new(Core.Settings.Weapon.TracerThickness/10, Core.Settings.Weapon.TracerThickness/10, (endPos - startPos).Magnitude)
    beamPart.Position = startPos + (endPos - startPos)/2
    beamPart.CFrame = CFrame.lookAt(startPos, endPos)
    beamPart.Material = Enum.Material[Core.Settings.Weapon.TracerMaterial]
    beamPart.Color = Core.Settings.Weapon.TracerColor
    beamPart.Transparency = 0
    beamPart.Parent = workspace

    local startTime = tick()
    local fadeDuration = 0.5
    local connection
    connection = Core.RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= fadeDuration then
            connection:Disconnect()
            beamPart:Destroy()
            Core.ActiveTracers = Core.ActiveTracers - 1
            return
        end
        beamPart.Transparency = elapsed / fadeDuration
    end)

    Core.Debris:AddItem(beamPart, fadeDuration)
end

-- Sky Color Implementation
local function UpdateSkyColor()
    local sky = Core.Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Core.Lighting
    end

    local selectedColor = Core.SkyColors[Core.Settings.Visuals.SkyColor]
    if selectedColor.SkyColor then
        sky.SkyboxBk = ""
        sky.SkyboxDn = ""
        sky.SkyboxFt = ""
        sky.SkyboxLf = ""
        sky.SkyboxRt = ""
        sky.SkyboxUp = ""
        sky.StarCount = 0
        sky.CelestialBodiesShown = false
        Core.Lighting.Ambient = selectedColor.Ambient
        local atmosphere = Core.Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Color = selectedColor.SkyColor
        end
    else
        sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tga"
        sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tga"
        sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tga"
        sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tga"
        sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tga"
        sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tga"
        sky.StarCount = 3000
        sky.CelestialBodiesShown = true
        Core.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        local atmosphere = Core.Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

function Visuals:EnableESP()
    Core.Settings.Visuals.ESPEnabled = true
    Core.ESPEnabled = true
    ScanPlayers()
    Core.RunService.Heartbeat:Connect(function()
        ScanPlayers()
        UpdateESP()
    end)
end

function Visuals:DisableESP()
    Core.Settings.Visuals.ESPEnabled = false
    Core.ESPEnabled = false
    for _, esp in pairs(ESP.Objects) do
        if esp.BillboardGui then
            esp.BillboardGui:Destroy()
        end
        if esp.Highlight then
            esp.Highlight:Destroy()
        end
    end
    ESP.Objects = {}
end

function Visuals:EnableChams()
    Core.Settings.Visuals.Chams = true
    for _, player in pairs(Core.Players:GetPlayers()) do
        ApplyChams(player)
    end
end

function Visuals:EnableBulletTracers()
    Core.Settings.Weapon.BulletTracers = true
end

function Visuals:UpdateHandChams()
    UpdateHandChams()
end

function Visuals:UpdateSkyColor()
    UpdateSkyColor()
end

return Visuals
