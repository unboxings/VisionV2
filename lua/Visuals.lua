-- Visuals.lua
local Visuals = {}

-- ESP Implementation
local ESP = {}
ESP.Objects = {}

local function CreateESP(player)
    if player == Core.Players.LocalPlayer then return end
    
    local esp = {
        Drawing = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
            Health = Drawing.new("Text"),
            Weapon = Drawing.new("Text"),
            Skeleton = {
                Head = Drawing.new("Line"),
                Torso = Drawing.new("Line"),
                LeftArm = Drawing.new("Line"),
                RightArm = Drawing.new("Line"),
                LeftLeg = Drawing.new("Line"),
                RightLeg = Drawing.new("Line")
            }
        }
    }
    
    for _, draw in pairs(esp.Drawing) do
        if type(draw) == "table" then
            for _, line in pairs(draw) do
                line.Visible = false
                line.Thickness = 1
                line.Color = Core.Settings.Visuals.EnemyColor
            end
        else
            draw.Visible = false
            draw.Color = Core.Settings.Visuals.EnemyColor
            draw.Thickness = 1
        end
    end
    
    ESP.Objects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(ESP.Objects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local screenPos, onScreen = Core.Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and Core.Settings.Visuals.ESPEnabled then
                local isTeam = Core.Settings.Visuals.TeamCheck and player.Team == Core.Players.LocalPlayer.Team
                local color = isTeam and Core.Settings.Visuals.TeamColor or Core.Settings.Visuals.EnemyColor
                
                if Core.Settings.Visuals.Box then
                    local scale = 2000 / (Core.Camera.CFrame.Position - hrp.Position).Magnitude
                    esp.Drawing.Box.Size = Vector2.new(scale * 2, scale * 3)
                    esp.Drawing.Box.Position = Vector2.new(screenPos.X - esp.Drawing.Box.Size.X / 2, screenPos.Y - esp.Drawing.Box.Size.Y / 2)
                    esp.Drawing.Box.Color = color
                    esp.Drawing.Box.Thickness = 2
                    esp.Drawing.Box.Visible = true
                else
                    esp.Drawing.Box.Visible = false
                end
                
                if Core.Settings.Visuals.Name then
                    esp.Drawing.Name.Text = player.Name
                    esp.Drawing.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                    esp.Drawing.Name.Size = 16
                    esp.Drawing.Name.Color = color
                    esp.Drawing.Name.Visible = true
                else
                    esp.Drawing.Name.Visible = false
                end
                
                if Core.Settings.Visuals.Distance then
                    local distance = (Core.Players.LocalPlayer.Character and Core.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (Core.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                    esp.Drawing.Distance.Text = string.format("%.0f studs", distance)
                    esp.Drawing.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
                    esp.Drawing.Distance.Size = 14
                    esp.Drawing.Distance.Color = color
                    esp.Drawing.Distance.Visible = true
                else
                    esp.Drawing.Distance.Visible = false
                end
                
                if Core.Settings.Visuals.Health and humanoid then
                    esp.Drawing.Health.Text = string.format("%d HP", humanoid.Health)
                    esp.Drawing.Health.Position = Vector2.new(screenPos.X + 50, screenPos.Y)
                    esp.Drawing.Health.Size = 14
                    esp.Drawing.Health.Color = color
                    esp.Drawing.Health.Visible = true
                else
                    esp.Drawing.Health.Visible = false
                end
                
                if Core.Settings.Visuals.Weapon then
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    esp.Drawing.Weapon.Text = tool and tool.Name or "None"
                    local yOffset = Core.Settings.Visuals.Name and -50 or -30
                    esp.Drawing.Weapon.Position = Vector2.new(screenPos.X, screenPos.Y + yOffset)
                    esp.Drawing.Weapon.Size = 14
                    esp.Drawing.Weapon.Color = color
                    esp.Drawing.Weapon.Visible = true
                else
                    esp.Drawing.Weapon.Visible = false
                end
                
                if Core.Settings.Visuals.Skeleton then
                    local parts = {
                        Head = player.Character:FindFirstChild("Head"),
                        Torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"),
                        LeftArm = player.Character:FindFirstChild("LeftUpperArm") or player.Character:FindFirstChild("Left Arm"),
                        RightArm = player.Character:FindFirstChild("RightUpperArm") or player.Character:FindFirstChild("Right Arm"),
                        LeftLeg = player.Character:FindFirstChild("LeftUpperLeg") or player.Character:FindFirstChild("Left Leg"),
                        RightLeg = player.Character:FindFirstChild("RightUpperLeg") or player.Character:FindFirstChild("Right Leg")
                    }
                    
                    if parts.Head and parts.Torso then
                        local headPos, headOnScreen = Core.Camera:WorldToViewportPoint(parts.Head.Position)
                        local torsoPos, torsoOnScreen = Core.Camera:WorldToViewportPoint(parts.Torso.Position)
                        if headOnScreen and torsoOnScreen then
                            esp.Drawing.Skeleton.Head.From = Vector2.new(headPos.X, headPos.Y)
                            esp.Drawing.Skeleton.Head.To = Vector2.new(torsoPos.X, torsoPos.Y)
                            esp.Drawing.Skeleton.Head.Color = color
                            esp.Drawing.Skeleton.Head.Visible = true
                        else
                            esp.Drawing.Skeleton.Head.Visible = false
                        end
                    else
                        esp.Drawing.Skeleton.Head.Visible = false
                    end
                    
                    if parts.Torso and parts.LeftArm then
                        local torsoPos, torsoOnScreen = Core.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = Core.Camera:WorldToViewportPoint(parts.LeftArm.Position)
                        if torsoOnScreen and armOnScreen then
                            esp.Drawing.Skeleton.LeftArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                            esp.Drawing.Skeleton.LeftArm.To = Vector2.new(armPos.X, armPos.Y)
                            esp.Drawing.Skeleton.LeftArm.Color = color
                            esp.Drawing.Skeleton.LeftArm.Visible = true
                        else
                            esp.Drawing.Skeleton.LeftArm.Visible = false
                        end
                    else
                        esp.Drawing.Skeleton.LeftArm.Visible = false
                    end
                    
                    if parts.Torso and parts.RightArm then
                        local torsoPos, torsoOnScreen = Core.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = Core.Camera:WorldToViewportPoint(parts.RightArm.Position)
                        if torsoOnScreen and armOnScreen then
                            esp.Drawing.Skeleton.RightArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                            esp.Drawing.Skeleton.RightArm.To = Vector2.new(armPos.X, armPos.Y)
                            esp.Drawing.Skeleton.RightArm.Color = color
                            esp.Drawing.Skeleton.RightArm.Visible = true
                        else
                            esp.Drawing.Skeleton.RightArm.Visible = false
                        end
                    else
                        esp.Drawing.Skeleton.RightArm.Visible = false
                    end
                    
                    if parts.Torso and parts.LeftLeg then
                        local torsoPos, torsoOnScreen = Core.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = Core.Camera:WorldToViewportPoint(parts.LeftLeg.Position)
                        if torsoOnScreen and legOnScreen then
                            esp.Drawing.Skeleton.LeftLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                            esp.Drawing.Skeleton.LeftLeg.To = Vector2.new(legPos.X, legPos.Y)
                            esp.Drawing.Skeleton.LeftLeg.Color = color
                            esp.Drawing.Skeleton.LeftLeg.Visible = true
                        else
                            esp.Drawing.Skeleton.LeftLeg.Visible = false
                        end
                    else
                        esp.Drawing.Skeleton.LeftLeg.Visible = false
                    end
                    
                    if parts.Torso and parts.RightLeg then
                        local torsoPos, torsoOnScreen = Core.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = Core.Camera:WorldToViewportPoint(parts.RightLeg.Position)
                        if torsoOnScreen and legOnScreen then
                            esp.Drawing.Skeleton.RightLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                            esp.Drawing.Skeleton.RightLeg.To = Vector2.new(legPos.X, legPos.Y)
                            esp.Drawing.Skeleton.RightLeg.Color = color
                            esp.Drawing.Skeleton.RightLeg.Visible = true
                        else
                            esp.Drawing.Skeleton.RightLeg.Visible = false
                        end
                    else
                        esp.Drawing.Skeleton.RightLeg.Visible = false
                    end
                else
                    for _, line in pairs(esp.Drawing.Skeleton) do
                        line.Visible = false
                    end
                end
            else
                for _, draw in pairs(esp.Drawing) do
                    if type(draw) == "table" then
                        for _, line in pairs(draw) do
                            line.Visible = false
                        end
                    else
                        draw.Visible = false
                    end
                end
            end
        else
            for _, draw in pairs(esp.Drawing) do
                if type(draw) == "table" then
                    for _, line in pairs(draw) do
                        line.Visible = false
                    end
                else
                    draw.Visible = false
                end
            end
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
        for _, draw in pairs(esp.Drawing) do
            if type(draw) == "table" then
                for _, line in pairs(draw) do
                    line:Remove()
                end
            else
                draw:Remove()
            end
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
