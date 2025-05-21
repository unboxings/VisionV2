local Visuals = {}
local VisionV2 = nil

-- ESP Implementation
local ESP = {}
ESP.Objects = {}

local function CreateESP(player)
    if player == VisionV2.Shared.LocalPlayer then return end
    
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
                line.Color = VisionV2.Shared.Settings.ESP.EnemyColor
            end
        else
            draw.Visible = false
            draw.Color = VisionV2.Shared.Settings.ESP.EnemyColor
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
            local screenPos, onScreen = VisionV2.Shared.Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and VisionV2.Shared.ESPEnabled then
                local isTeam = VisionV2.Shared.Settings.ESP.TeamCheck and player.Team == VisionV2.Shared.LocalPlayer.Team
                local color = isTeam and VisionV2.Shared.Settings.ESP.TeamColor or VisionV2.Shared.Settings.ESP.EnemyColor
                
                if VisionV2.Shared.Settings.ESP.Box then
                    local scale = 2000 / (VisionV2.Shared.Camera.CFrame.Position - hrp.Position).Magnitude
                    esp.Drawing.Box.Size = Vector2.new(scale * 2, scale * 3)
                    esp.Drawing.Box.Position = Vector2.new(screenPos.X - esp.Drawing.Box.Size.X / 2, screenPos.Y - esp.Drawing.Box.Size.Y / 2)
                    esp.Drawing.Box.Color = color
                    esp.Drawing.Box.Thickness = 2
                    esp.Drawing.Box.Visible = true
                else
                    esp.Drawing.Box.Visible = false
                end
                
                if VisionV2.Shared.Settings.ESP.Name then
                    esp.Drawing.Name.Text = player.Name
                    esp.Drawing.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                    esp.Drawing.Name.Size = 16
                    esp.Drawing.Name.Color = color
                    esp.Drawing.Name.Visible = true
                else
                    esp.Drawing.Name.Visible = false
                end
                
                if VisionV2.Shared.Settings.ESP.Distance then
                    local distance = (VisionV2.Shared.LocalPlayer.Character and VisionV2.Shared.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (VisionV2.Shared.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                    esp.Drawing.Distance.Text = string.format("%.0f studs", distance)
                    esp.Drawing.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
                    esp.Drawing.Distance.Size = 14
                    esp.Drawing.Distance.Color = color
                    esp.Drawing.Distance.Visible = true
                else
                    esp.Drawing.Distance.Visible = false
                end
                
                if VisionV2.Shared.Settings.ESP.Health and humanoid then
                    esp.Drawing.Health.Text = string.format("%d HP", humanoid.Health)
                    esp.Drawing.Health.Position = Vector2.new(screenPos.X + 50, screenPos.Y)
                    esp.Drawing.Health.Size = 14
                    esp.Drawing.Health.Color = color
                    esp.Drawing.Health.Visible = true
                else
                    esp.Drawing.Health.Visible = false
                end
                
                if VisionV2.Shared.Settings.ESP.Weapon then
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    esp.Drawing.Weapon.Text = tool and tool.Name or "None"
                    local yOffset = VisionV2.Shared.Settings.ESP.Name and -50 or -30
                    esp.Drawing.Weapon.Position = Vector2.new(screenPos.X, screenPos.Y + yOffset)
                    esp.Drawing.Weapon.Size = 14
                    esp.Drawing.Weapon.Color = color
                    esp.Drawing.Weapon.Visible = true
                else
                    esp.Drawing.Weapon.Visible = false
                end
                
                if VisionV2.Shared.Settings.ESP.Skeleton then
                    local parts = {
                        Head = player.Character:FindFirstChild("Head"),
                        Torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"),
                        LeftArm = player.Character:FindFirstChild("LeftUpperArm") or player.Character:FindFirstChild("Left Arm"),
                        RightArm = player.Character:FindFirstChild("RightUpperArm") or player.Character:FindFirstChild("Right Arm"),
                        LeftLeg = player.Character:FindFirstChild("LeftUpperLeg") or player.Character:FindFirstChild("Left Leg"),
                        RightLeg = player.Character:FindFirstChild("RightUpperLeg") or player.Character:FindFirstChild("Right Leg")
                    }
                    
                    if parts.Head and parts.Torso then
                        local headPos, headOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Head.Position)
                        local torsoPos, torsoOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Torso.Position)
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
                        local torsoPos, torsoOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.LeftArm.Position)
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
                        local torsoPos, torsoOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.RightArm.Position)
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
                        local torsoPos, torsoOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.LeftLeg.Position)
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
                        local torsoPos, torsoOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(parts.RightLeg.Position)
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

-- Bullet Tracers Implementation
local function CreateBulletTracer(startPos, endPos)
    if not VisionV2.Shared.Settings.Weapon.BulletTracers or VisionV2.Shared.ActiveTracers >= VisionV2.Shared.MaxTracers then return end
    VisionV2.Shared.ActiveTracers = VisionV2.Shared.ActiveTracers + 1

    local beamPart = Instance.new("Part")
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Size = Vector3.new(VisionV2.Shared.Settings.Weapon.TracerThickness/10, VisionV2.Shared.Settings.Weapon.TracerThickness/10, (endPos - startPos).Magnitude)
    beamPart.Position = startPos + (endPos - startPos)/2
    beamPart.CFrame = CFrame.lookAt(startPos, endPos)
    beamPart.Material = Enum.Material[VisionV2.Shared.Settings.Weapon.TracerMaterial]
    beamPart.Color = VisionV2.Shared.Settings.Weapon.TracerColor
    beamPart.Transparency = 0
    beamPart.Parent = workspace

    local startTime = tick()
    local fadeDuration = 0.5
    local connection
    connection = VisionV2.Shared.RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= fadeDuration then
            connection:Disconnect()
            beamPart:Destroy()
            VisionV2.Shared.ActiveTracers = VisionV2.Shared.ActiveTracers - 1
            return
        end
        beamPart.Transparency = elapsed / fadeDuration
    end)

    VisionV2.Shared.Debris:AddItem(beamPart, fadeDuration)
end

local function SetupBulletTracers()
    local weaponConnections = {}
    
    local function ConnectWeapon(weapon)
        local handle = weapon:WaitForChild("Handle", 5)
        if not handle then return end
        weaponConnections[weapon] = weapon.Activated:Connect(function()
            if not VisionV2.Shared.Settings.Weapon.BulletTracers then return end
            
            local muzzlePos = handle.Position
            local targetPos
            if VisionV2.Shared.SilentAimEnabled and VisionV2.Shared.CurrentTarget and VisionV2.Shared.CurrentTarget.Character and VisionV2.Shared.CurrentTarget.Character:FindFirstChild(VisionV2.Shared.Settings.Aimbot.TargetPart) then
                local targetPart = VisionV2.Shared.CurrentTarget.Character[VisionV2.Shared.Settings.Aimbot.TargetPart]
                targetPos = targetPart.Position
                if VisionV2.Shared.Settings.Aimbot.PredictMovement and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
                    local hrp = targetPart.Parent.HumanoidRootPart
                    local velocity = hrp.Velocity
                    local distance = (VisionV2.Shared.Camera.CFrame.Position - targetPos).Magnitude
                    local timeToHit = distance / VisionV2.Shared.Settings.Aimbot.BulletSpeed
                    targetPos = targetPos + (velocity * timeToHit)
                end
            else
                local unitRay = VisionV2.Shared.Camera:ScreenPointToRay(VisionV2.Shared.Mouse.X, VisionV2.Shared.Mouse.Y)
                targetPos = muzzlePos + unitRay.Direction * 1000
            end
            if targetPos then
                CreateBulletTracer(muzzlePos, targetPos)
            end
        end)
    end

    VisionV2.Shared.LocalPlayer.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                ConnectWeapon(child)
            end
        end)
    end)
    
    if VisionV2.Shared.LocalPlayer.Character then
        for _, child in pairs(VisionV2.Shared.LocalPlayer.Character:GetChildren()) do
            if child:IsA("Tool") then
                ConnectWeapon(child)
            end
        end
    end
end

-- Target Dot Implementation
local function CreateTargetDot()
    local dot = Drawing.new("Circle")
    dot.Thickness = 1
    dot.NumSides = 20
    dot.Radius = 5
    dot.Visible = false
    dot.Color = VisionV2.Shared.Settings.ESP.EnemyColor
    dot.Filled = true
    dot.Transparency = 1
    return dot
end

local function UpdateTargetDot()
    if not VisionV2.Shared.TargetDot then return end
    if VisionV2.Shared.SilentAimEnabled and VisionV2.Shared.CurrentTarget and VisionV2.Shared.CurrentTarget.Character and VisionV2.Shared.CurrentTarget.Character:FindFirstChild(VisionV2.Shared.Settings.Aimbot.TargetPart) then
        local targetPart = VisionV2.Shared.CurrentTarget.Character[VisionV2.Shared.Settings.Aimbot.TargetPart]
        local headPos = targetPart.Position
        if VisionV2.Shared.Settings.Aimbot.PredictMovement and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
            local hrp = targetPart.Parent.HumanoidRootPart
            local velocity = hrp.Velocity
            local distance = (VisionV2.Shared.Camera.CFrame.Position - headPos).Magnitude
            local timeToHit = distance / VisionV2.Shared.Settings.Aimbot.BulletSpeed
            headPos = headPos + (velocity * timeToHit)
        end
        if headPos then
            local screenPos, onScreen = VisionV2.Shared.Camera:WorldToViewportPoint(headPos)
            if onScreen then
                VisionV2.Shared.TargetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                VisionV2.Shared.TargetDot.Visible = true
            else
                VisionV2.Shared.TargetDot.Visible = false
            end
        else
            VisionV2.Shared.TargetDot.Visible = false
        end
    else
        VisionV2.Shared.TargetDot.Visible = false
    end
end

-- Chams Implementation
local ChamsHighlights = {}
local function ApplyChams(player)
    if player == VisionV2.Shared.LocalPlayer or not VisionV2.Shared.Settings.Visuals.Chams then return end
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (VisionV2.Shared.Camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude
        if distance > 2000 then return end
        
        local highlight = ChamsHighlights[player]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = player.Character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            ChamsHighlights[player] = highlight
        end
        
        local isVisible = #VisionV2.Shared.Camera:GetPartsObscuringTarget({player.Character[VisionV2.Shared.Settings.Aimbot.TargetPart].Position}, {VisionV2.Shared.LocalPlayer.Character or {}, player.Character}) == 0
        highlight.FillColor = isVisible and VisionV2.Shared.Settings.Visuals.ChamsVisibleColor or VisionV2.Shared.Settings.Visuals.ChamsOccludedColor
        highlight.FillTransparency = VisionV2.Shared.Settings.Visuals.ChamsTransparency
        highlight.OutlineColor = Color3.fromRGB(255, 182, 193)
        highlight.OutlineTransparency = 0
        highlight.Enabled = true
    end
end

local function ResetChams(player)
    if player == VisionV2.Shared.LocalPlayer then return end
    
    local highlight = ChamsHighlights[player]
    if highlight then
        highlight:Destroy()
        ChamsHighlights[player] = nil
    end
end

-- Hand Chams Implementation
local function ApplyHandChams(character)
    if not VisionV2.Shared.Settings.Visuals.HandChams or not character then return end
    
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
        part.Color = VisionV2.Shared.Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[VisionV2.Shared.Settings.Visuals.HandChamsMaterial]
        part.Transparency = VisionV2.Shared.Settings.Visuals.HandChamsTransparency
    end
    
    for _, part in pairs(weaponParts) do
        part.Color = VisionV2.Shared.Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[VisionV2.Shared.Settings.Visuals.HandChamsMaterial]
        part.Transparency = VisionV2.Shared.Settings.Visuals.HandChamsTransparency
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
    if not VisionV2.Shared.LocalPlayer.Character then return end
    if VisionV2.Shared.Settings.Visuals.HandChams then
        ApplyHandChams(VisionV2.Shared.LocalPlayer.Character)
    else
        ResetHandChams(VisionV2.Shared.LocalPlayer.Character)
    end
end

-- Sky Color Implementation
local function UpdateSkyColor()
    local sky = VisionV2.Shared.Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = VisionV2.Shared.Lighting
    end

    local selectedColor = VisionV2.Shared.SkyColors[VisionV2.Shared.Settings.Visuals.SkyColor]
    if selectedColor.SkyColor then
        sky.SkyboxBk = ""
        sky.SkyboxDn = ""
        sky.SkyboxFt = ""
        sky.SkyboxLf = ""
        sky.SkyboxRt = ""
        sky.SkyboxUp = ""
        sky.StarCount = 0
        sky.CelestialBodiesShown = false
        VisionV2.Shared.Lighting.Ambient = selectedColor.Ambient
        local atmosphere = VisionV2.Shared.Lighting:FindFirstChildOfClass("Atmosphere")
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
        VisionV2.Shared.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        local atmosphere = VisionV2.Shared.Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- Player Scanning
function Visuals.ScanPlayers()
    for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
        if not ESP.Objects[player] and player ~= VisionV2.Shared.LocalPlayer then
            CreateESP(player)
        end
        if VisionV2.Shared.Settings.Visuals.Chams then
            ApplyChams(player)
        else
            ResetChams(player)
        end
    end
    UpdateHandChams()
end

function Visuals.RefreshChams()
    for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
        ApplyChams(player)
    end
end

-- Visuals Tab
local function SetupVisualsTab()
    local ESPSection = VisionV2.Shared.VisualsTab:Section({
        Name = "ESP Settings",
        Side = "Left"
    })

    ESPSection:Toggle({
        Name = "Enabled",
        Flag = "ESP_Enabled",
        Default = VisionV2.Shared.ESPEnabled,
        Callback = function(Value)
            VisionV2.Shared.ESPEnabled = Value
        end
    })

    ESPSection:Toggle({
        Name = "Box ESP",
        Flag = "ESP_Box",
        Default = VisionV2.Shared.Settings.ESP.Box,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Box = Value
        end
    })

    ESPSection:Toggle({
        Name = "Name ESP",
        Flag = "ESP_Name",
        Default = VisionV2.Shared.Settings.ESP.Name,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Name = Value
        end
    })

    ESPSection:Toggle({
        Name = "Distance ESP",
        Flag = "ESP_Distance",
        Default = VisionV2.Shared.Settings.ESP.Distance,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Distance = Value
        end
    })

    ESPSection:Toggle({
        Name = "Health ESP",
        Flag = "ESP_Health",
        Default = VisionV2.Shared.Settings.ESP.Health,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Health = Value
        end
    })

    ESPSection:Toggle({
        Name = "Weapon ESP",
        Flag = "ESP_Weapon",
        Default = VisionV2.Shared.Settings.ESP.Weapon,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Weapon = Value
        end
    })

    ESPSection:Toggle({
        Name = "Skeleton ESP",
        Flag = "ESP_Skeleton",
        Default = VisionV2.Shared.Settings.ESP.Skeleton,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.Skeleton = Value
        end
    })

    ESPSection:Toggle({
        Name = "Team Check",
        Flag = "ESP_TeamCheck",
        Default = VisionV2.Shared.Settings.ESP.TeamCheck,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.TeamCheck = Value
        end
    })

    ESPSection:Colorpicker({
        Name = "Enemy Color",
        Flag = "ESP_EnemyColor",
        Default = VisionV2.Shared.Settings.ESP.EnemyColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.EnemyColor = Value
        end
    })

    ESPSection:Colorpicker({
        Name = "Team Color",
        Flag = "ESP_TeamColor",
        Default = VisionV2.Shared.Settings.ESP.TeamColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.ESP.TeamColor = Value
        end
    })

    local VisualsChamsSection = VisionV2.Shared.VisualsTab:Section({
        Name = "Chams Settings",
        Side = "Left"
    })

    VisualsChamsSection:Toggle({
        Name = "Player Chams",
        Flag = "Visuals_Chams",
        Default = VisionV2.Shared.Settings.Visuals.Chams,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.Chams = Value
            for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
                if Value then
                    ApplyChams(player)
                else
                    ResetChams(player)
                end
            end
        end
    })

    VisualsChamsSection:Toggle({
        Name = "Hand Chams",
        Flag = "Visuals_HandChams",
        Default = VisionV2.Shared.Settings.Visuals.HandChams,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.HandChams = Value
            UpdateHandChams()
        end
    })

    VisualsChamsSection:Slider({
        Name = "Player Transparency",
        Flag = "Visuals_ChamsTransparency",
        Default = VisionV2.Shared.Settings.Visuals.ChamsTransparency * 10,
        Min = 0,
        Max = 10,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.ChamsTransparency = Value / 10
            if VisionV2.Shared.Settings.Visuals.Chams then
                for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
                    ApplyChams(player)
                end
            end
        end
    })

    VisualsChamsSection:Slider({
        Name = "Hand Transparency",
        Flag = "Visuals_HandChamsTransparency",
        Default = VisionV2.Shared.Settings.Visuals.HandChamsTransparency * 10,
        Min = 0,
        Max = 10,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.HandChamsTransparency = Value / 10
            UpdateHandChams()
        end
    })

    VisualsChamsSection:Colorpicker({
        Name = "Visible Color",
        Flag = "Visuals_ChamsVisibleColor",
        Default = VisionV2.Shared.Settings.Visuals.ChamsVisibleColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.ChamsVisibleColor = Value
            if VisionV2.Shared.Settings.Visuals.Chams then
                for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
                    ApplyChams(player)
                end
            end
        end
    })

    VisualsChamsSection:Colorpicker({
        Name = "Occluded Color",
        Flag = "Visuals_ChamsOccludedColor",
        Default = VisionV2.Shared.Settings.Visuals.ChamsOccludedColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.ChamsOccludedColor = Value
            if VisionV2.Shared.Settings.Visuals.Chams then
                for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
                    ApplyChams(player)
                end
            end
        end
    })

    VisualsChamsSection:Colorpicker({
        Name = "Hand Chams Color",
        Flag = "Visuals_HandChamsColor",
        Default = VisionV2.Shared.Settings.Visuals.HandChamsColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.HandChamsColor = Value
            UpdateHandChams()
        end
    })

    VisualsChamsSection:Dropdown({
        Name = "Chams Material",
        Flag = "Visuals_ChamsMaterial",
        Content = VisionV2.Shared.Materials,
        Default = VisionV2.Shared.Settings.Visuals.ChamsMaterial,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.ChamsMaterial = Value
            if VisionV2.Shared.Settings.Visuals.Chams then
                for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
                    ApplyChams(player)
                end
            end
        end
    })

    VisualsChamsSection:Dropdown({
        Name = "Hand Chams Material",
        Flag = "Visuals_HandChamsMaterial",
        Content = VisionV2.Shared.Materials,
        Default = VisionV2.Shared.Settings.Visuals.HandChamsMaterial,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.HandChamsMaterial = Value
            UpdateHandChams()
        end
    })

    local VisualsBulletTracersSection = VisionV2.Shared.VisualsTab:Section({
        Name = "Bullet Tracers",
        Side = "Right"
    })

    VisualsBulletTracersSection:Toggle({
        Name = "Enabled",
        Flag = "Weapon_BulletTracers",
        Default = VisionV2.Shared.Settings.Weapon.BulletTracers,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.BulletTracers = Value
            if Value then
                SetupBulletTracers()
            end
        end
    })

    VisualsBulletTracersSection:Colorpicker({
        Name = "Tracer Color",
        Flag = "Weapon_TracerColor",
        Default = VisionV2.Shared.Settings.Weapon.TracerColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.TracerColor = Value
        end
    })

    VisualsBulletTracersSection:Slider({
        Name = "Tracer Thickness",
        Flag = "Weapon_TracerThickness",
        Default = VisionV2.Shared.Settings.Weapon.TracerThickness,
        Min = 1,
        Max = 5,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.TracerThickness = Value
        end
    })

    VisualsBulletTracersSection:Dropdown({
        Name = "Tracer Material",
        Flag = "Weapon_TracerMaterial",
        Content = VisionV2.Shared.Materials,
        Default = VisionV2.Shared.Settings.Weapon.TracerMaterial,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.TracerMaterial = Value
        end
    })

    local VisualsWorldSection = VisionV2.Shared.VisualsTab:Section({
        Name = "World Settings",
        Side = "Right"
    })

    VisualsWorldSection:Toggle({
        Name = "Fullbright",
        Flag = "Visuals_Fullbright",
        Default = VisionV2.Shared.Settings.Visuals.Fullbright,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.Fullbright = Value
            if Value then
                game.Lighting.Brightness = 1
                game.Lighting.GlobalShadows = false
            else
                game.Lighting.Brightness = 0
                game.Lighting.GlobalShadows = true
            end
        end
    })

    VisualsWorldSection:Toggle({
        Name = "No Fog",
        Flag = "Visuals_NoFog",
        Default = VisionV2.Shared.Settings.Visuals.NoFog,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.NoFog = Value
            if Value then
                game.Lighting.FogEnd = 100000
            else
                game.Lighting.FogEnd = 1000
            end
        end
    })

    VisualsWorldSection:Dropdown({
        Name = "Sky Color",
        Flag = "Visuals_SkyColor",
        Content = {"Default", "Pink", "Sunset", "Night", "Purple"},
        Default = VisionV2.Shared.Settings.Visuals.SkyColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.SkyColor = Value
            UpdateSkyColor()
        end
    })

    VisualsWorldSection:Slider({
        Name = "Time of Day",
        Flag = "Visuals_TimeOfDay",
        Default = VisionV2.Shared.Settings.Visuals.TimeOfDay,
        Min = 0,
        Max = 24,
        Callback = function(Value)
            VisionV2.Shared.Settings.Visuals.TimeOfDay = Value
            game.Lighting.ClockTime = Value
        end
    })
end

-- Misc Tab
local function SetupMiscTab()
    local MiscSection = VisionV2.Shared.MiscTab:Section({
        Name = "Miscellaneous",
        Side = "Left"
    })

    MiscSection:Toggle({
        Name = "No Recoil",
        Flag = "Weapon_NoRecoil",
        Default = VisionV2.Shared.Settings.Weapon.NoRecoil,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.NoRecoil = Value
        end
    })

    MiscSection:Toggle({
        Name = "No Spread",
        Flag = "Weapon_NoSpread",
        Default = VisionV2.Shared.Settings.Weapon.NoSpread,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.NoSpread = Value
        end
    })

    MiscSection:Toggle({
        Name = "Rapid Fire",
        Flag = "Weapon_RapidFire",
        Default = VisionV2.Shared.Settings.Weapon.RapidFire,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.RapidFire = Value
        end
    })

    MiscSection:Slider({
        Name = "Fire Rate",
        Flag = "Weapon_FireRate",
        Default = VisionV2.Shared.Settings.Weapon.FireRate,
        Min = 50,
        Max = 1000,
        Callback = function(Value)
            VisionV2.Shared.Settings.Weapon.FireRate = Value
        end
    })
end

-- Settings Tab
local function SetupSettingsTab()
    local SettingsSection = VisionV2.Shared.SettingsTab:Section({
        Name = "Settings",
        Side = "Left"
    })

    local ProfilesSection = VisionV2.Shared.SettingsTab:Section({
        Name = "Profiles",
        Side = "Left"
    })

    local InformationSection = VisionV2.Shared.SettingsTab:Section({
        Name = "Information",
        Side = "Right"
    })

    SettingsSection:Keybind({
        Name = "Toggle UI",
        Flag = "Toggle_UI",
        Default = Enum.KeyCode.RightShift,
        Callback = function()
            VisionV2.Toggle(not VisionV2.GetToggleState())
        end
    })
end

function Visuals.Init(vision)
    VisionV2 = vision
    VisionV2.Shared.TargetDot = CreateTargetDot()
    SetupVisualsTab()
    SetupMiscTab()
    SetupSettingsTab()
    if VisionV2.Shared.Settings.Weapon.BulletTracers then
        SetupBulletTracers()
    end
    UpdateSkyColor()
end

function Visuals.Update()
    UpdateESP()
    UpdateTargetDot()
    UpdateHandChams()
end

return Visuals
