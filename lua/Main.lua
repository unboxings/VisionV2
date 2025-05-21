-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local VisionV2 = {}
local Toggled = true
local ESPEnabled = false
local FOVCircle = nil
local AimbotEnabled = false
local SilentAimEnabled = false
local BulletTracersEnabled = false
local TargetDot = nil
local ActiveTracers = 0
local MaxTracers = 10
local ThirdPersonEnabled = false
local ZoomEnabled = false
local ZoomKey = Enum.UserInputType.MouseButton3
local DefaultFOV = 70
local ZoomFOV = 20
local OriginalSensitivity = UserInputService.MouseDeltaSensitivity
local CurrentTarget = nil
local AimbotRunning = false
local AimbotAnimation = nil
local Settings = {
    Aimbot = {
        Enabled = false,
        FOV = 90,
        Sensitivity = 0,
        ThirdPerson = false,
        ThirdPersonSensitivity = 3,
        TargetPart = "Head",
        ShowFOV = true,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        BulletSpeed = 1000,
        PredictMovement = true
    },
    AimbotFOV = {
        Enabled = true,
        Visible = true,
        Amount = 90,
        Color = Color3.fromRGB(255, 182, 193),
        LockedColor = Color3.fromRGB(255, 192, 203),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },
    ESP = {
        Box = false,
        Name = false,
        Distance = false,
        Health = false,
        Weapon = false,
        Skeleton = false,
        TeamCheck = true,
        EnemyColor = Color3.fromRGB(255, 182, 193),
        TeamColor = Color3.fromRGB(255, 192, 203)
    },
    Weapon = {
        NoRecoil = false,
        NoSpread = false,
        RapidFire = false,
        BulletTracers = false,
        TracerColor = Color3.fromRGB(255, 182, 193),
        TracerThickness = 2,
        FireRate = 100,
        TracerMaterial = "Neon"
    },
    Visuals = {
        Chams = false,
        ChamsVisibleColor = Color3.fromRGB(255, 182, 193),
        ChamsOccludedColor = Color3.fromRGB(255, 192, 203),
        ChamsTransparency = 0.5,
        ChamsMaterial = "Neon",
        HandChams = false,
        HandChamsColor = Color3.fromRGB(255, 182, 193),
        HandChamsTransparency = 0.3,
        HandChamsMaterial = "Neon",
        Fullbright = false,
        NoFog = false,
        TimeOfDay = 12,
        SkyColor = "Default"
    }
}

-- Constants
local FONT = Enum.Font.GothamBold
local PRIMARY_COLOR = Color3.fromRGB(40, 40, 50)
local SECONDARY_COLOR = Color3.fromRGB(50, 50, 60)
local ACCENT_COLOR = Color3.fromRGB(255, 182, 193)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local SECONDARY_TEXT_COLOR = Color3.fromRGB(180, 180, 195)
local SHADOW_COLOR = Color3.fromRGB(20, 20, 25)
local TOGGLE_ON_COLOR = Color3.fromRGB(255, 182, 193)
local TOGGLE_OFF_COLOR = Color3.fromRGB(60, 60, 80)
local OUTLINE_COLOR = Color3.fromRGB(255, 182, 193)

-- Sky Color Presets
local SkyColors = {
    Default = {SkyColor = nil, Ambient = nil},
    Pink = {SkyColor = Color3.fromRGB(255, 182, 193), Ambient = Color3.fromRGB(255, 192, 203)},
    Sunset = {SkyColor = Color3.fromRGB(255, 147, 79), Ambient = Color3.fromRGB(200, 100, 50)},
    Night = {SkyColor = Color3.fromRGB(25, 25, 50), Ambient = Color3.fromRGB(20, 20, 30)},
    Purple = {SkyColor = Color3.fromRGB(147, 112, 219), Ambient = Color3.fromRGB(100, 80, 150)}
}

-- Materials for Chams and Hand Chams
local Materials = {"Neon", "ForceField", "Glass", "SmoothPlastic"}

-- Utility Functions
local function CreateInstance(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function MakeDraggable(frame)
    local dragToggle = nil
    local dragSpeed = 0.1
    local dragStart = nil
    local startPos = nil

    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            UpdateDrag(input)
        end
    end)
end

local function ConvertVector(Vector)
    return Vector2.new(Vector.X, Vector.Y)
end

-- Silent Aim Prediction
local function PredictTargetPosition(targetPart)
    if not targetPart or not targetPart.Parent then return targetPart.Position end
    local targetPos = targetPart.Position
    if Settings.Aimbot.PredictMovement and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        local hrp = targetPart.Parent.HumanoidRootPart
        local velocity = hrp.Velocity
        local distance = (Camera.CFrame.Position - targetPos).Magnitude
        local timeToHit = distance / Settings.Aimbot.BulletSpeed
        targetPos = targetPos + (velocity * timeToHit)
    end
    return targetPos
end

-- Silent Aim Implementation
local SilentAimConnections = {}
local function SetupSilentAim()
    for _, connection in pairs(SilentAimConnections) do
        connection:Disconnect()
    end
    SilentAimConnections = {}

    if not LocalPlayer.Character then return end
    
    local character = LocalPlayer.Character
    local weapon = character and character:FindFirstChildOfClass("Tool")
    if not weapon then return end

    local fireEvent = weapon:FindFirstChild("Fire") or weapon:FindFirstChild("FireServer")
    if fireEvent and fireEvent:IsA("RemoteEvent") then
        SilentAimConnections[#SilentAimConnections + 1] = weapon.Activated:Connect(function()
            if not SilentAimEnabled then return end
            
            local target = GetClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
                local muzzle = weapon:FindFirstChild("Handle") or weapon:FindFirstChildWhichIsA("BasePart")
                if muzzle then
                    local targetPos = PredictTargetPosition(target.Character[Settings.Aimbot.TargetPart])
                    if targetPos then
                        fireEvent:FireServer(targetPos)
                    end
                end
            end
        end)
    end
end

local function DisableSilentAim()
    for _, connection in pairs(SilentAimConnections) do
        connection:Disconnect()
    end
    SilentAimConnections = {}
end

-- Third-Person Camera
local function UpdateThirdPerson()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
    if ThirdPersonEnabled then
        local offset = Vector3.new(5, 5, 10)
        local lookAt = humanoidRootPart.Position
        local cameraPos = humanoidRootPart.Position + offset

        local cameraCFrame = CFrame.new(cameraPos, lookAt) * CFrame.Angles(0, math.rad(humanoidRootPart.Orientation.Y), 0)
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = Camera.CFrame:Lerp(cameraCFrame, 0.1)

        RunService:BindToRenderStep("ThirdPersonCamera", Enum.RenderPriority.Camera.Value, function()
            if ThirdPersonEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local newHumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                local newCameraPos = newHumanoidRootPart.Position + offset
                local newLookAt = newHumanoidRootPart.Position
                local newCFrame = CFrame.new(newCameraPos, newLookAt) * CFrame.Angles(0, math.rad(newHumanoidRootPart.Orientation.Y), 0)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.1)
            end
        end)
    else
        Camera.CameraType = Enum.CameraType.Custom
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        Camera.CameraSubject = humanoid or humanoidRootPart
        RunService:UnbindFromRenderStep("ThirdPersonCamera")
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart")
    character:WaitForChild("Humanoid")
    if Settings.Aimbot.ThirdPerson then
        ThirdPersonEnabled = true
        UpdateThirdPerson()
    end
end)

if LocalPlayer.Character then
    LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    if Settings.Aimbot.ThirdPerson then
        ThirdPersonEnabled = true
        UpdateThirdPerson()
    end
end

local function HideHandsOnADS()
    if not LocalPlayer.Character then return end
    local arms = {}
    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("MeshPart") and (part.Name:match("Arm") or part.Name:match("Hand")) then
            table.insert(arms, part)
        end
    end

    if AimbotRunning then
        for _, part in pairs(arms) do
            part.Transparency = 1
        end
    else
        for _, part in pairs(arms) do
            part.Transparency = Settings.Visuals.HandChams and Settings.Visuals.HandChamsTransparency or 0
        end
    end
end

-- Aimbot Implementation
local function CancelLock()
    CurrentTarget = nil
    Settings.AimbotFOV.Color = Settings.AimbotFOV.Color
    UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    if AimbotAnimation then
        AimbotAnimation:Cancel()
        AimbotAnimation = nil
    end
end

local function GetClosestPlayer()
    local RequiredDistance = Settings.AimbotFOV.Enabled and Settings.AimbotFOV.Amount or 2000
    local closestPlayer = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.Aimbot.TargetPart) and player.Character:FindFirstChildOfClass("Humanoid") then
            if Settings.Aimbot.ThirdPerson and player == LocalPlayer then continue end
            if Settings.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if Settings.Aimbot.AliveCheck and player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
            if Settings.Aimbot.WallCheck then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character or {}, Camera}
                local rayOrigin = Camera.CFrame.Position
                local rayDirection = (player.Character[Settings.Aimbot.TargetPart].Position - rayOrigin).Unit * 1000
                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                if result and result.Instance and not result.Instance:IsDescendantOf(player.Character) then continue end
            end

            local Vector, OnScreen = Camera:WorldToViewportPoint(player.Character[Settings.Aimbot.TargetPart].Position)
            Vector = ConvertVector(Vector)
            local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

            if Distance < RequiredDistance and OnScreen then
                RequiredDistance = Distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

-- Zoom Implementation with Smooth Transition
local ZoomTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local function UpdateZoom()
    local targetFOV = ZoomEnabled and ZoomFOV or DefaultFOV
    local tween = TweenService:Create(Camera, ZoomTweenInfo, {FieldOfView = targetFOV})
    tween:Play()
end

-- Handle Zoom Key Input
local function SetupZoomInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == ZoomKey or input.KeyCode == ZoomKey then
            ZoomEnabled = true
            UpdateZoom()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == ZoomKey or input.KeyCode == ZoomKey then
            ZoomEnabled = false
            UpdateZoom()
        end
    end)
end

-- Bullet Tracers Implementation
local function CreateBulletTracer(startPos, endPos)
    if not Settings.Weapon.BulletTracers or ActiveTracers >= MaxTracers then return end
    ActiveTracers = ActiveTracers + 1

    local beamPart = Instance.new("Part")
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Size = Vector3.new(Settings.Weapon.TracerThickness/10, Settings.Weapon.TracerThickness/10, (endPos - startPos).Magnitude)
    beamPart.Position = startPos + (endPos - startPos)/2
    beamPart.CFrame = CFrame.lookAt(startPos, endPos)
    beamPart.Material = Enum.Material[Settings.Weapon.TracerMaterial]
    beamPart.Color = Settings.Weapon.TracerColor
    beamPart.Transparency = 0
    beamPart.Parent = workspace

    local startTime = tick()
    local fadeDuration = 0.5
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= fadeDuration then
            connection:Disconnect()
            beamPart:Destroy()
            ActiveTracers = ActiveTracers - 1
            return
        end
        beamPart.Transparency = elapsed / fadeDuration
    end)

    Debris:AddItem(beamPart, fadeDuration)
end

-- Hook weapon firing for tracers
local function SetupBulletTracers()
    local weaponConnections = {}
    
    local function ConnectWeapon(weapon)
        local handle = weapon:WaitForChild("Handle", 5)
        if not handle then return end
        weaponConnections[weapon] = weapon.Activated:Connect(function()
            if not Settings.Weapon.BulletTracers then return end
            
            local muzzlePos = handle.Position
            local targetPos
            if SilentAimEnabled and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
                targetPos = PredictTargetPosition(CurrentTarget.Character[Settings.Aimbot.TargetPart])
            else
                local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                targetPos = muzzlePos + unitRay.Direction * 1000
            end
            if targetPos then
                CreateBulletTracer(muzzlePos, targetPos)
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                ConnectWeapon(child)
            end
        end)
    end)
    
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
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
    dot.Color = Settings.ESP.EnemyColor
    dot.Filled = true
    dot.Transparency = 1
    return dot
end

local function UpdateTargetDot()
    if not TargetDot then return end
    if SilentAimEnabled and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
        local headPos = PredictTargetPosition(CurrentTarget.Character[Settings.Aimbot.TargetPart])
        if headPos then
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen then
                TargetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                TargetDot.Visible = true
            else
                TargetDot.Visible = false
            end
        else
            TargetDot.Visible = false
        end
    else
        TargetDot.Visible = false
    end
end

-- ESP Implementation
local ESP = {}
ESP.Objects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    
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
                line.Color = Settings.ESP.EnemyColor
            end
        else
            draw.Visible = false
            draw.Color = Settings.ESP.EnemyColor
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
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and ESPEnabled then
                local isTeam = Settings.ESP.TeamCheck and player.Team == LocalPlayer.Team
                local color = isTeam and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
                
                if Settings.ESP.Box then
                    local scale = 2000 / (Camera.CFrame.Position - hrp.Position).Magnitude
                    esp.Drawing.Box.Size = Vector2.new(scale * 2, scale * 3)
                    esp.Drawing.Box.Position = Vector2.new(screenPos.X - esp.Drawing.Box.Size.X / 2, screenPos.Y - esp.Drawing.Box.Size.Y / 2)
                    esp.Drawing.Box.Color = color
                    esp.Drawing.Box.Thickness = 2
                    esp.Drawing.Box.Visible = true
                else
                    esp.Drawing.Box.Visible = false
                end
                
                if Settings.ESP.Name then
                    esp.Drawing.Name.Text = player.Name
                    esp.Drawing.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                    esp.Drawing.Name.Size = 16
                    esp.Drawing.Name.Color = color
                    esp.Drawing.Name.Visible = true
                else
                    esp.Drawing.Name.Visible = false
                end
                
                if Settings.ESP.Distance then
                    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                    esp.Drawing.Distance.Text = string.format("%.0f studs", distance)
                    esp.Drawing.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
                    esp.Drawing.Distance.Size = 14
                    esp.Drawing.Distance.Color = color
                    esp.Drawing.Distance.Visible = true
                else
                    esp.Drawing.Distance.Visible = false
                end
                
                if Settings.ESP.Health and humanoid then
                    esp.Drawing.Health.Text = string.format("%d HP", humanoid.Health)
                    esp.Drawing.Health.Position = Vector2.new(screenPos.X + 50, screenPos.Y)
                    esp.Drawing.Health.Size = 14
                    esp.Drawing.Health.Color = color
                    esp.Drawing.Health.Visible = true
                else
                    esp.Drawing.Health.Visible = false
                end
                
                if Settings.ESP.Weapon then
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    esp.Drawing.Weapon.Text = tool and tool.Name or "None"
                    local yOffset = Settings.ESP.Name and -50 or -30
                    esp.Drawing.Weapon.Position = Vector2.new(screenPos.X, screenPos.Y + yOffset)
                    esp.Drawing.Weapon.Size = 14
                    esp.Drawing.Weapon.Color = color
                    esp.Drawing.Weapon.Visible = true
                else
                    esp.Drawing.Weapon.Visible = false
                end
                
                if Settings.ESP.Skeleton then
                    local parts = {
                        Head = player.Character:FindFirstChild("Head"),
                        Torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"),
                        LeftArm = player.Character:FindFirstChild("LeftUpperArm") or player.Character:FindFirstChild("Left Arm"),
                        RightArm = player.Character:FindFirstChild("RightUpperArm") or player.Character:FindFirstChild("Right Arm"),
                        LeftLeg = player.Character:FindFirstChild("LeftUpperLeg") or player.Character:FindFirstChild("Left Leg"),
                        RightLeg = player.Character:FindFirstChild("RightUpperLeg") or player.Character:FindFirstChild("Right Leg")
                    }
                    
                    if parts.Head and parts.Torso then
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(parts.Head.Position)
                        local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(parts.Torso.Position)
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
                        local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = Camera:WorldToViewportPoint(parts.LeftArm.Position)
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
                        local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(parts.Torso.Position)
                        local armPos, armOnScreen = Camera:WorldToViewportPoint(parts.RightArm.Position)
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
                        local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = Camera:WorldToViewportPoint(parts.LeftLeg.Position)
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
                        local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(parts.Torso.Position)
                        local legPos, legOnScreen = Camera:WorldToViewportPoint(parts.RightLeg.Position)
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

-- FOV Circle
local function CreateFOVCircle()
    local circle = Drawing.new("Circle")
    circle.Thickness = Settings.AimbotFOV.Thickness
    circle.NumSides = Settings.AimbotFOV.Sides
    circle.Radius = Settings.AimbotFOV.Amount
    circle.Visible = Settings.AimbotFOV.Visible and (AimbotEnabled or SilentAimEnabled)
    circle.Color = Settings.AimbotFOV.Color
    circle.Filled = Settings.AimbotFOV.Filled
    circle.Transparency = Settings.AimbotFOV.Transparency
    circle.Position = UserInputService:GetMouseLocation()
    return circle
end

-- Chams Implementation
local ChamsHighlights = {}
local function ApplyChams(player)
    if player == LocalPlayer or not Settings.Visuals.Chams then return end
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (Camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude
        if distance > 2000 then return end
        
        local highlight = ChamsHighlights[player]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = player.Character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            ChamsHighlights[player] = highlight
        end
        
        local isVisible = #Camera:GetPartsObscuringTarget({player.Character[Settings.Aimbot.TargetPart].Position}, {LocalPlayer.Character or {}, player.Character}) == 0
        highlight.FillColor = isVisible and Settings.Visuals.ChamsVisibleColor or Settings.Visuals.ChamsOccludedColor
        highlight.FillTransparency = Settings.Visuals.ChamsTransparency
        highlight.OutlineColor = OUTLINE_COLOR
        highlight.OutlineTransparency = 0
        highlight.Enabled = true
    end
end

local function ResetChams(player)
    if player == LocalPlayer then return end
    
    local highlight = ChamsHighlights[player]
    if highlight then
        highlight:Destroy()
        ChamsHighlights[player] = nil
    end
end

-- Hand Chams Implementation
local function ApplyHandChams(character)
    if not Settings.Visuals.HandChams or not character then return end
    
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
        part.Color = Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[Settings.Visuals.HandChamsMaterial]
        part.Transparency = Settings.Visuals.HandChamsTransparency
    end
    
    for _, part in pairs(weaponParts) do
        part.Color = Settings.Visuals.HandChamsColor
        part.Material = Enum.Material[Settings.Visuals.HandChamsMaterial]
        part.Transparency = Settings.Visuals.HandChamsTransparency
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
    if not LocalPlayer.Character then return end
    if Settings.Visuals.HandChams then
        ApplyHandChams(LocalPlayer.Character)
    else
        ResetHandChams(LocalPlayer.Character)
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart", 5)
    character:WaitForChild("Humanoid", 5)
    UpdateHandChams()
end)

if LocalPlayer.Character then
    LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
    UpdateHandChams()
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            UpdateHandChams()
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            UpdateHandChams()
        end
    end)
end)

-- Player Scanning
local function ScanPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if not ESP.Objects[player] and player ~= LocalPlayer then
            CreateESP(player)
        end
        if Settings.Visuals.Chams then
            ApplyChams(player)
        else
            ResetChams(player)
        end
    end
    UpdateHandChams()
end

Players.PlayerRemoving:Connect(function(player)
    if ESP.Objects[player] then
        for _, draw in pairs(ESP.Objects[player].Drawing) do
            if type(draw) == "table" then
                for _, line in pairs(draw) do
                    line:Remove()
                end
            else
                draw:Remove()
            end
        end
        ESP.Objects[player] = nil
    end
    ResetChams(player)
end)

-- Sky Color Implementation
local function UpdateSkyColor()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end

    local selectedColor = SkyColors[Settings.Visuals.SkyColor]
    if selectedColor.SkyColor then
        sky.SkyboxBk = ""
        sky.SkyboxDn = ""
        sky.SkyboxFt = ""
        sky.SkyboxLf = ""
        sky.SkyboxRt = ""
        sky.SkyboxUp = ""
        sky.StarCount = 0
        sky.CelestialBodiesShown = false
        Lighting.Ambient = selectedColor.Ambient
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
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
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- AirHub V2 GUI Implementation (Modified to VisionV2)
local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub-V2/main/src/UI%20Library.lua"))()
local MainFrame = GUI:Load()

-- Create Popup for Date and Time
local ScreenGui = Instance.new("ScreenGui")
local DateTimePopup = Instance.new("TextLabel")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
DateTimePopup.Parent = ScreenGui
DateTimePopup.Size = UDim2.new(0, 300, 0, 100)
DateTimePopup.Position = UDim2.new(0.5, -150, 0.5, -50)
DateTimePopup.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
DateTimePopup.BorderSizePixel = 0
DateTimePopup.Text = "Today's date and time is 02:42 AM PDT on Wednesday, May 21, 2025"
DateTimePopup.TextColor3 = Color3.fromRGB(255, 255, 255)
DateTimePopup.Font = Enum.Font.GothamBold
DateTimePopup.TextSize = 18
DateTimePopup.TextWrapped = true
DateTimePopup.Visible = true

-- Hide popup after 5 seconds
delay(5, function()
    DateTimePopup:Destroy()
    ScreenGui:Destroy()
end)

-- Tabs
local Combat, CombatSignal = MainFrame:Tab("Combat")
local Visuals = MainFrame:Tab("Visuals")
local Misc = MainFrame:Tab("Misc")
local SettingsTab = MainFrame:Tab("Settings")

-- Combat Tab
local AimbotSection = Combat:Section({
    Name = "Aimbot Settings",
    Side = "Left"
})

AimbotSection:Toggle({
    Name = "Enabled",
    Flag = "Aimbot_Enabled",
    Default = Settings.Aimbot.Enabled,
    Callback = function(Value)
        AimbotEnabled = Value
        Settings.Aimbot.Enabled = Value
        if not Value then
            CancelLock()
        end
    end
})

AimbotSection:Toggle({
    Name = "Silent Aim",
    Flag = "Silent_Aim_Enabled",
    Default = SilentAimEnabled,
    Callback = function(Value)
        SilentAimEnabled = Value
        if Value then
            SetupSilentAim()
        else
            DisableSilentAim()
        end
    end
})

AimbotSection:Toggle({
    Name = "Show FOV",
    Flag = "Aimbot_ShowFOV",
    Default = Settings.Aimbot.ShowFOV,
    Callback = function(Value)
        Settings.AimbotFOV.Visible = Value
        if FOVCircle then
            FOVCircle.Visible = Value and (AimbotEnabled or SilentAimEnabled)
        end
    end
})

AimbotSection:Toggle({
    Name = "Team Check",
    Flag = "Aimbot_TeamCheck",
    Default = Settings.Aimbot.TeamCheck,
    Callback = function(Value)
        Settings.Aimbot.TeamCheck = Value
    end
})

AimbotSection:Toggle({
    Name = "Alive Check",
    Flag = "Aimbot_AliveCheck",
    Default = Settings.Aimbot.AliveCheck,
    Callback = function(Value)
        Settings.Aimbot.AliveCheck = Value
    end
})

AimbotSection:Toggle({
    Name = "Wall Check",
    Flag = "Aimbot_WallCheck",
    Default = Settings.Aimbot.WallCheck,
    Callback = function(Value)
        Settings.Aimbot.WallCheck = Value
    end
})

AimbotSection:Toggle({
    Name = "Third Person",
    Flag = "Aimbot_ThirdPerson",
    Default = Settings.Aimbot.ThirdPerson,
    Callback = function(Value)
        Settings.Aimbot.ThirdPerson = Value
        ThirdPersonEnabled = Value
        UpdateThirdPerson()
    end
})

AimbotSection:Toggle({
    Name = "Predict Movement",
    Flag = "Aimbot_PredictMovement",
    Default = Settings.Aimbot.PredictMovement,
    Callback = function(Value)
        Settings.Aimbot.PredictMovement = Value
    end
})

AimbotSection:Keybind({
    Name = "Zoom Key",
    Flag = "Aimbot_ZoomKey",
    Default = ZoomKey,
    Callback = function(Keybind)
        ZoomKey = Keybind
    end
})

AimbotSection:Slider({
    Name = "FOV",
    Flag = "Aimbot_FOV",
    Default = Settings.AimbotFOV.Amount,
    Min = 10,
    Max = 300,
    Callback = function(Value)
        Settings.AimbotFOV.Amount = Value
        if FOVCircle then
            FOVCircle.Radius = Value
        end
    end
})

AimbotSection:Slider({
    Name = "Sensitivity",
    Flag = "Aimbot_Sensitivity",
    Default = Settings.Aimbot.Sensitivity * 100,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        Settings.Aimbot.Sensitivity = Value / 100
    end
})

AimbotSection:Slider({
    Name = "ThirdPerson Sensitivity",
    Flag = "Aimbot_ThirdPersonSensitivity",
    Default = Settings.Aimbot.ThirdPersonSensitivity,
    Min = 0.1,
    Max = 5,
    Callback = function(Value)
        Settings.Aimbot.ThirdPersonSensitivity = Value
    end
})

AimbotSection:Slider({
    Name = "Bullet Speed",
    Flag = "Aimbot_BulletSpeed",
    Default = Settings.Aimbot.BulletSpeed,
    Min = 100,
    Max = 5000,
    Callback = function(Value)
        Settings.Aimbot.BulletSpeed = Value
    end
})

AimbotSection:Dropdown({
    Name = "Target Part",
    Flag = "Aimbot_TargetPart",
    Content = {"Head", "HumanoidRootPart", "Torso"},
    Default = Settings.Aimbot.TargetPart,
    Callback = function(Value)
        Settings.Aimbot.TargetPart = Value
    end
})

local AimbotFOVSection = Combat:Section({
    Name = "Field Of View Settings",
    Side = "Right"
})

AimbotFOVSection:Toggle({
    Name = "Enabled",
    Flag = "AimbotFOV_Enabled",
    Default = Settings.AimbotFOV.Enabled,
    Callback = function(Value)
        Settings.AimbotFOV.Enabled = Value
    end
})

AimbotFOVSection:Toggle({
    Name = "Visible",
    Flag = "AimbotFOV_Visible",
    Default = Settings.AimbotFOV.Visible,
    Callback = function(Value)
        Settings.AimbotFOV.Visible = Value
        if FOVCircle then
            FOVCircle.Visible = Value and (AimbotEnabled or SilentAimEnabled)
        end
    end
})

AimbotFOVSection:Slider({
    Name = "Transparency",
    Flag = "AimbotFOV_Transparency",
    Default = Settings.AimbotFOV.Transparency * 10,
    Min = 0,
    Max = 10,
    Callback = function(Value)
        Settings.AimbotFOV.Transparency = Value / 10
        if FOVCircle then
            FOVCircle.Transparency = Value / 10
        end
    end
})

AimbotFOVSection:Slider({
    Name = "Sides",
    Flag = "AimbotFOV_Sides",
    Default = Settings.AimbotFOV.Sides,
    Min = 3,
    Max = 60,
    Callback = function(Value)
        Settings.AimbotFOV.Sides = Value
        if FOVCircle then
            FOVCircle.NumSides = Value
        end
    end
})

AimbotFOVSection:Slider({
    Name = "Thickness",
    Flag = "AimbotFOV_Thickness",
    Default = Settings.AimbotFOV.Thickness,
    Min = 1,
    Max = 5,
    Callback = function(Value)
        Settings.AimbotFOV.Thickness = Value
        if FOVCircle then
            FOVCircle.Thickness = Value
        end
    end
})

AimbotFOVSection:Colorpicker({
    Name = "Color",
    Flag = "AimbotFOV_Color",
    Default = Settings.AimbotFOV.Color,
    Callback = function(Value)
        Settings.AimbotFOV.Color = Value
        if FOVCircle then
            FOVCircle.Color = CurrentTarget and Settings.AimbotFOV.LockedColor or Value
        end
    end
})

AimbotFOVSection:Colorpicker({
    Name = "Locked Color",
    Flag = "AimbotFOV_LockedColor",
    Default = Settings.AimbotFOV.LockedColor,
    Callback = function(Value)
        Settings.AimbotFOV.LockedColor = Value
    end
})

-- Visuals Tab
local ESPSection = Visuals:Section({
    Name = "ESP Settings",
    Side = "Left"
})

ESPSection:Toggle({
    Name = "Enabled",
    Flag = "ESP_Enabled",
    Default = ESPEnabled,
    Callback = function(Value)
        ESPEnabled = Value
    end
})

ESPSection:Toggle({
    Name = "Box ESP",
    Flag = "ESP_Box",
    Default = Settings.ESP.Box,
    Callback = function(Value)
        Settings.ESP.Box = Value
    end
})

ESPSection:Toggle({
    Name = "Name ESP",
    Flag = "ESP_Name",
    Default = Settings.ESP.Name,
    Callback = function(Value)
        Settings.ESP.Name = Value
    end
})

ESPSection:Toggle({
    Name = "Distance ESP",
    Flag = "ESP_Distance",
    Default = Settings.ESP.Distance,
    Callback = function(Value)
        Settings.ESP.Distance = Value
    end
})

ESPSection:Toggle({
    Name = "Health ESP",
    Flag = "ESP_Health",
    Default = Settings.ESP.Health,
    Callback = function(Value)
        Settings.ESP.Health = Value
    end
})

ESPSection:Toggle({
    Name = "Weapon ESP",
    Flag = "ESP_Weapon",
    Default = Settings.ESP.Weapon,
    Callback = function(Value)
        Settings.ESP.Weapon = Value
    end
})

ESPSection:Toggle({
    Name = "Skeleton ESP",
    Flag = "ESP_Skeleton",
    Default = Settings.ESP.Skeleton,
    Callback = function(Value)
        Settings.ESP.Skeleton = Value
    end
})

ESPSection:Toggle({
    Name = "Team Check",
    Flag = "ESP_TeamCheck",
    Default = Settings.ESP.TeamCheck,
    Callback = function(Value)
        Settings.ESP.TeamCheck = Value
    end
})

ESPSection:Colorpicker({
    Name = "Enemy Color",
    Flag = "ESP_EnemyColor",
    Default = Settings.ESP.EnemyColor,
    Callback = function(Value)
        Settings.ESP.EnemyColor = Value
    end
})

ESPSection:Colorpicker({
    Name = "Team Color",
    Flag = "ESP_TeamCheck",
    Default = Settings.ESP.TeamColor,
    Callback = function(Value)
        Settings.ESP.TeamColor = Value
    end
})

local VisualsChamsSection = Visuals:Section({
    Name = "Chams Settings",
    Side = "Left"
})

VisualsChamsSection:Toggle({
    Name = "Player Chams",
    Flag = "Visuals_Chams",
    Default = Settings.Visuals.Chams,
    Callback = function(Value)
        Settings.Visuals.Chams = Value
        for _, player in pairs(Players:GetPlayers()) do
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
    Default = Settings.Visuals.HandChams,
    Callback = function(Value)
        Settings.Visuals.HandChams = Value
        UpdateHandChams()
    end
})

VisualsChamsSection:Slider({
    Name = "Player Transparency",
    Flag = "Visuals_ChamsTransparency",
    Default = Settings.Visuals.ChamsTransparency * 10,
    Min = 0,
    Max = 10,
    Callback = function(Value)
        Settings.Visuals.ChamsTransparency = Value / 10
        if Settings.Visuals.Chams then
            for _, player in pairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        end
    end
})

VisualsChamsSection:Slider({
    Name = "Hand Transparency",
    Flag = "Visuals_HandChamsTransparency",
    Default = Settings.Visuals.HandChamsTransparency * 10,
    Min = 0,
    Max = 10,
    Callback = function(Value)
        Settings.Visuals.HandChamsTransparency = Value / 10
        UpdateHandChams()
    end
})

VisualsChamsSection:Colorpicker({
    Name = "Visible Color",
    Flag = "Visuals_ChamsVisibleColor",
    Default = Settings.Visuals.ChamsVisibleColor,
    Callback = function(Value)
        Settings.Visuals.ChamsVisibleColor = Value
        if Settings.Visuals.Chams then
            for _, player in pairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        end
    end
})

VisualsChamsSection:Colorpicker({
    Name = "Occluded Color",
    Flag = "Visuals_ChamsOccludedColor",
    Default = Settings.Visuals.ChamsOccludedColor,
    Callback = function(Value)
        Settings.Visuals.ChamsOccludedColor = Value
        if Settings.Visuals.Chams then
            for _, player in pairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        end
    end
})

VisualsChamsSection:Colorpicker({
    Name = "Hand Chams Color",
    Flag = "Visuals_HandChamsColor",
    Default = Settings.Visuals.HandChamsColor,
    Callback = function(Value)
        Settings.Visuals.HandChamsColor = Value
        UpdateHandChams()
    end
})

VisualsChamsSection:Dropdown({
    Name = "Chams Material",
    Flag = "Visuals_ChamsMaterial",
    Content = Materials,
    Default = Settings.Visuals.ChamsMaterial,
    Callback = function(Value)
        Settings.Visuals.ChamsMaterial = Value
        if Settings.Visuals.Chams then
            for _, player in pairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        end
    end
})

VisualsChamsSection:Dropdown({
    Name = "Hand Chams Material",
    Flag = "Visuals_HandChamsMaterial",
    Content = Materials,
    Default = Settings.Visuals.HandChamsMaterial,
    Callback = function(Value)
        Settings.Visuals.HandChamsMaterial = Value
        UpdateHandChams()
    end
})

local VisualsBulletTracersSection = Visuals:Section({
    Name = "Bullet Tracers",
    Side = "Right"
})

VisualsBulletTracersSection:Toggle({
    Name = "Enabled",
    Flag = "Weapon_BulletTracers",
    Default = Settings.Weapon.BulletTracers,
    Callback = function(Value)
        Settings.Weapon.BulletTracers = Value
        if Value then
            SetupBulletTracers()
        end
    end
})

VisualsBulletTracersSection:Colorpicker({
    Name = "Tracer Color",
    Flag = "Weapon_TracerColor",
    Default = Settings.Weapon.TracerColor,
    Callback = function(Value)
        Settings.Weapon.TracerColor = Value
    end
})

VisualsBulletTracersSection:Slider({
    Name = "Tracer Thickness",
    Flag = "Weapon_TracerThickness",
    Default = Settings.Weapon.TracerThickness,
    Min = 1,
    Max = 5,
    Callback = function(Value)
        Settings.Weapon.TracerThickness = Value
    end
})

VisualsBulletTracersSection:Dropdown({
    Name = "Tracer Material",
    Flag = "Weapon_TracerMaterial",
    Content = Materials,
    Default = Settings.Weapon.TracerMaterial,
    Callback = function(Value)
        Settings.Weapon.TracerMaterial = Value
    end
})

local VisualsWorldSection = Visuals:Section({
    Name = "World Settings",
    Side = "Right"
})

VisualsWorldSection:Toggle({
    Name = "Fullbright",
    Flag = "Visuals_Fullbright",
    Default = Settings.Visuals.Fullbright,
    Callback = function(Value)
        Settings.Visuals.Fullbright = Value
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
    Default = Settings.Visuals.NoFog,
    Callback = function(Value)
        Settings.Visuals.NoFog = Value
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
    Default = Settings.Visuals.SkyColor,
    Callback = function(Value)
        Settings.Visuals.SkyColor = Value
        UpdateSkyColor()
    end
})

VisualsWorldSection:Slider({
    Name = "Time of Day",
    Flag = "Visuals_TimeOfDay",
    Default = Settings.Visuals.TimeOfDay,
    Min = 0,
    Max = 24,
    Callback = function(Value)
        Settings.Visuals.TimeOfDay = Value
        game.Lighting.ClockTime = Value
    end
})

-- Misc Tab
local MiscSection = Misc:Section({
    Name = "Miscellaneous",
    Side = "Left"
})

MiscSection:Toggle({
    Name = "No Recoil",
    Flag = "Weapon_NoRecoil",
    Default = Settings.Weapon.NoRecoil,
    Callback = function(Value)
        Settings.Weapon.NoRecoil = Value
    end
})

MiscSection:Toggle({
    Name = "No Spread",
    Flag = "Weapon_NoSpread",
    Default = Settings.Weapon.NoSpread,
    Callback = function(Value)
        Settings.Weapon.NoSpread = Value
    end
})

MiscSection:Toggle({
    Name = "Rapid Fire",
    Flag = "Weapon_RapidFire",
    Default = Settings.Weapon.RapidFire,
    Callback = function(Value)
        Settings.Weapon.RapidFire = Value
    end
})

MiscSection:Slider({
    Name = "Fire Rate",
    Flag = "Weapon_FireRate",
    Default = Settings.Weapon.FireRate,
    Min = 50,
    Max = 1000,
    Callback = function(Value)
        Settings.Weapon.FireRate = Value
    end
})

-- Settings Tab
local SettingsSection = SettingsTab:Section({
    Name = "Settings",
    Side = "Left"
})

local ProfilesSection = SettingsTab:Section({
    Name = "Profiles",
    Side = "Left"
})

local InformationSection = SettingsTab:Section({
    Name = "Information",
    Side = "Right"
})

SettingsSection:Keybind({
    Name = "Show / Hide GUI",
    Flag = "UI_Toggle",
    Default = Enum.KeyCode.RightShift,
    Blacklist = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3},
    Callback = function(_, NewKeybind)
        if not NewKeybind then
            GUI:Close()
        end
    end
})

SettingsSection:Button({
    Name = "Unload Script",
    Callback = function()
        GUI:Unload()
        if FOVCircle then
            FOVCircle:Remove()
        end
        if TargetDot then
            TargetDot:Remove()
        end
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
        ResetHandChams(LocalPlayer.Character)
        for _, player in pairs(Players:GetPlayers()) do
            ResetChams(player)
        end
        CancelLock()
    end
})

local ConfigList = ProfilesSection:Dropdown({
    Name = "Configurations",
    Flag = "Config_Dropdown",
    Content = GUI:GetConfigs()
})

ProfilesSection:Box({
    Name = "Configuration Name",
    Flag = "Config_Name",
    Placeholder = "Config Name"
})

ProfilesSection:Button({
    Name = "Load Configuration",
    Callback = function()
        GUI:LoadConfig(GUI.flags["Config_Dropdown"])
    end
})

ProfilesSection:Button({
    Name = "Delete Configuration",
    Callback = function()
        GUI:DeleteConfig(GUI.flags["Config_Dropdown"])
        ConfigList:Refresh(GUI:GetConfigs())
    end
})

ProfilesSection:Button({
    Name = "Save Configuration",
    Callback = function()
        GUI:SaveConfig(GUI.flags["Config_Dropdown"] or GUI.flags["Config_Name"])
        ConfigList:Refresh(GUI:GetConfigs())
    end
})

InformationSection:Label("Made by @quarries")

-- GUI Customization
local ScreenGui = MainFrame.ScreenGui
local MainFrameInstance = ScreenGui:FindFirstChild("MainFrame")
if MainFrameInstance then
    MainFrameInstance.Size = UDim2.new(0, 600, 0, 400)
    MainFrameInstance.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrameInstance.BackgroundColor3 = PRIMARY_COLOR
    MainFrameInstance.BackgroundTransparency = 0
    MakeDraggable(MainFrameInstance)
    
    local Glow = CreateInstance("ImageLabel", {
        Name = "Glow",
        Parent = MainFrameInstance,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -20, 0, -20),
        Size = UDim2.new(1, 40, 1, 40),
        ZIndex = -1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = ACCENT_COLOR,
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        SliceScale = 0.1
    })
    
    local Outline = CreateInstance("Frame", {
        Name = "Outline",
        Parent = MainFrameInstance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        ZIndex = -1
    })
    
    local TopOutline = CreateInstance("Frame", {
        Parent = Outline,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0)
    })
    
    local BottomOutline = CreateInstance("Frame", {
        Parent = Outline,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2)
    })
    
    local LeftOutline = CreateInstance("Frame", {
        Parent = Outline,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0),
        Position = UDim2.new(0, 0, 0, 0)
    })
    
    local RightOutline = CreateInstance("Frame", {
        Parent = Outline,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0),
        Position = UDim2.new(1, -2, 0, 0)
    })
end

-- Initialize
for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
    ApplyChams(player)
end
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
    ApplyChams(player)
end)

FOVCircle = CreateFOVCircle()
TargetDot = CreateTargetDot()

-- Optimized Render Loop
local lastUpdate = tick()
local updateInterval = 1/30

RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick()
    if currentTime - lastUpdate < updateInterval then return end
    lastUpdate = currentTime

    if FOVCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Settings.AimbotFOV.Amount
        FOVCircle.Thickness = Settings.AimbotFOV.Thickness
        FOVCircle.Filled = Settings.AimbotFOV.Filled
        FOVCircle.NumSides = Settings.AimbotFOV.Sides
        FOVCircle.Color = CurrentTarget and Settings.AimbotFOV.LockedColor or Settings.AimbotFOV.Color
        FOVCircle.Transparency = Settings.AimbotFOV.Transparency
        FOVCircle.Visible = Settings.AimbotFOV.Visible and (AimbotEnabled or SilentAimEnabled)
    end
    
    UpdateTargetDot()
    HideHandsOnADS()
    
    if AimbotEnabled or SilentAimEnabled then
        CurrentTarget = GetClosestPlayer()
    end
    
    if AimbotRunning and AimbotEnabled and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
        if Settings.Aimbot.ThirdPerson then
            local Vector = Camera:WorldToViewportPoint(CurrentTarget.Character[Settings.Aimbot.TargetPart].Position)
            local mousePos = UserInputService:GetMouseLocation()
            local deltaX = (Vector.X - mousePos.X) * Settings.Aimbot.ThirdPersonSensitivity
            local deltaY = (Vector.Y - mousePos.Y) * Settings.Aimbot.ThirdPersonSensitivity
        else
            local targetPos = PredictTargetPosition(CurrentTarget.Character[Settings.Aimbot.TargetPart])
            if targetPos and Camera then
                if Settings.Aimbot.Sensitivity > 0 then
                    if AimbotAnimation then
                        AimbotAnimation:Cancel()
                    end
                    AimbotAnimation = TweenService:Create(Camera, TweenInfo.new(Settings.Aimbot.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                    })
                    AimbotAnimation:Play()
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                end
                UserInputService.MouseDeltaSensitivity = 0
            end
        end
    else
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
        if AimbotAnimation then
            AimbotAnimation:Cancel()
            AimbotAnimation = nil
        end
    end
end)

-- Optimized Heartbeat Loop
local lastChamsRefresh = tick()
local chamsRefreshInterval = 5

RunService.Heartbeat:Connect(function()
    ScanPlayers()
    UpdateESP()
    
    local currentTime = tick()
    if currentTime - lastChamsRefresh >= chamsRefreshInterval and Settings.Visuals.Chams then
        for _, player in pairs(Players:GetPlayers()) do
            ApplyChams(player)
        end
        lastChamsRefresh = currentTime
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            if Settings.Weapon.NoRecoil then
                -- Implement no recoil (game-specific)
            end
            if Settings.Weapon.NoSpread then
                -- Implement no spread (game-specific)
            end
            if Settings.Weapon.RapidFire then
                -- Implement rapid fire (game-specific)
            end
        end
    end
end)

-- Input Handling
local Typing = false
UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)
UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not Typing and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotRunning = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not Typing and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotRunning = false
        if AimbotEnabled then
            CancelLock()
        end
    end
end)

-- Initialize Zoom and Tracers
Camera.FieldOfView = DefaultFOV
SetupZoomInput()
SetupBulletTracers()

-- VisionV2 Interface
VisionV2 = {
    UI = MainFrame,
    Toggle = function(visible)
        MainFrame.MainFrame.Visible = visible
        Toggled = visible
    end,
    GetToggleState = function()
        return Toggled
    end
}

CombatSignal:Fire()
MainFrame.MainFrame.Visible = true

return VisionV2
