local Aimbot = {}
local VisionV2 = nil
local FOVCircle = nil

-- Silent Aim Prediction
local function PredictTargetPosition(targetPart)
    if not targetPart or not targetPart.Parent then return targetPart.Position end
    local targetPos = targetPart.Position
    if VisionV2.Shared.Settings.Aimbot.PredictMovement and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        local hrp = targetPart.Parent.HumanoidRootPart
        local velocity = hrp.Velocity
        local distance = (VisionV2.Shared.Camera.CFrame.Position - targetPos).Magnitude
        local timeToHit = distance / VisionV2.Shared.Settings.Aimbot.BulletSpeed
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

    if not VisionV2.Shared.LocalPlayer.Character then return end
    
    local character = VisionV2.Shared.LocalPlayer.Character
    local weapon = character and character:FindFirstChildOfClass("Tool")
    if not weapon then return end

    local fireEvent = weapon:FindFirstChild("Fire") or weapon:FindFirstChild("FireServer")
    if fireEvent and fireEvent:IsA("RemoteEvent") then
        SilentAimConnections[#SilentAimConnections + 1] = weapon.Activated:Connect(function()
            if not VisionV2.Shared.SilentAimEnabled then return end
            
            local target = Aimbot.GetClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild(VisionV2.Shared.Settings.Aimbot.TargetPart) then
                local muzzle = weapon:FindFirstChild("Handle") or weapon:FindFirstChildWhichIsA("BasePart")
                if muzzle then
                    local targetPos = PredictTargetPosition(target.Character[VisionV2.Shared.Settings.Aimbot.TargetPart])
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
    if not VisionV2.Shared.LocalPlayer.Character or not VisionV2.Shared.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local humanoidRootPart = VisionV2.Shared.LocalPlayer.Character.HumanoidRootPart
    if VisionV2.Shared.ThirdPersonEnabled then
        local offset = Vector3.new(5, 5, 10)
        local lookAt = humanoidRootPart.Position
        local cameraPos = humanoidRootPart.Position + offset

        local cameraCFrame = CFrame.new(cameraPos, lookAt) * CFrame.Angles(0, math.rad(humanoidRootPart.Orientation.Y), 0)
        VisionV2.Shared.Camera.CameraType = Enum.CameraType.Scriptable
        VisionV2.Shared.Camera.CFrame = VisionV2.Shared.Camera.CFrame:Lerp(cameraCFrame, 0.1)

        VisionV2.Shared.RunService:BindToRenderStep("ThirdPersonCamera", Enum.RenderPriority.Camera.Value, function()
            if VisionV2.Shared.ThirdPersonEnabled and VisionV2.Shared.LocalPlayer.Character and VisionV2.Shared.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local newHumanoidRootPart = VisionV2.Shared.LocalPlayer.Character.HumanoidRootPart
                local newCameraPos = newHumanoidRootPart.Position + offset
                local newLookAt = newHumanoidRootPart.Position
                local newCFrame = CFrame.new(newCameraPos, newLookAt) * CFrame.Angles(0, math.rad(newHumanoidRootPart.Orientation.Y), 0)
                VisionV2.Shared.Camera.CFrame = VisionV2.Shared.Camera.CFrame:Lerp(newCFrame, 0.1)
            end
        end)
    else
        VisionV2.Shared.Camera.CameraType = Enum.CameraType.Custom
        local humanoid = VisionV2.Shared.LocalPlayer.Character:FindFirstChild("Humanoid")
        VisionV2.Shared.Camera.CameraSubject = humanoid or humanoidRootPart
        VisionV2.Shared.RunService:UnbindFromRenderStep("ThirdPersonCamera")
    end
end

local function HideHandsOnADS()
    if not VisionV2.Shared.LocalPlayer.Character then return end
    local arms = {}
    for _, part in pairs(VisionV2.Shared.LocalPlayer.Character:GetChildren()) do
        if part:IsA("MeshPart") and (part.Name:match("Arm") or part.Name:match("Hand")) then
            table.insert(arms, part)
        end
    end

    if VisionV2.Shared.AimbotRunning then
        for _, part in pairs(arms) do
            part.Transparency = 1
        end
    else
        for _, part in pairs(arms) do
            part.Transparency = VisionV2.Shared.Settings.Visuals.HandChams and VisionV2.Shared.Settings.Visuals.HandChamsTransparency or 0
        end
    end
end

function Aimbot.CancelLock()
    VisionV2.Shared.CurrentTarget = nil
    VisionV2.Shared.Settings.AimbotFOV.Color = VisionV2.Shared.Settings.AimbotFOV.Color
    VisionV2.Shared.UserInputService.MouseDeltaSensitivity = VisionV2.Shared.OriginalSensitivity
    if VisionV2.Shared.AimbotAnimation then
        VisionV2.Shared.AimbotAnimation:Cancel()
        VisionV2.Shared.AimbotAnimation = nil
    end
end

function Aimbot.GetClosestPlayer()
    local RequiredDistance = VisionV2.Shared.Settings.AimbotFOV.Enabled and VisionV2.Shared.Settings.AimbotFOV.Amount or 2000
    local closestPlayer = nil

    for _, player in pairs(VisionV2.Shared.Players:GetPlayers()) do
        if player ~= VisionV2.Shared.LocalPlayer and player.Character and player.Character:FindFirstChild(VisionV2.Shared.Settings.Aimbot.TargetPart) and player.Character:FindFirstChildOfClass("Humanoid") then
            if VisionV2.Shared.Settings.Aimbot.ThirdPerson and player == VisionV2.Shared.LocalPlayer then continue end
            if VisionV2.Shared.Settings.Aimbot.TeamCheck and player.Team == VisionV2.Shared.LocalPlayer.Team then continue end
            if VisionV2.Shared.Settings.Aimbot.AliveCheck and player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
            if VisionV2.Shared.Settings.Aimbot.WallCheck then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {VisionV2.Shared.LocalPlayer.Character or {}, VisionV2.Shared.Camera}
                local rayOrigin = VisionV2.Shared.Camera.CFrame.Position
                local rayDirection = (player.Character[VisionV2.Shared.Settings.Aimbot.TargetPart].Position - rayOrigin).Unit * 1000
                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                if result and result.Instance and not result.Instance:IsDescendantOf(player.Character) then continue end
            end

            local Vector, OnScreen = VisionV2.Shared.Camera:WorldToViewportPoint(player.Character[VisionV2.Shared.Settings.Aimbot.TargetPart].Position)
            Vector = VisionV2.Shared.ConvertVector(Vector)
            local Distance = (VisionV2.Shared.UserInputService:GetMouseLocation() - Vector).Magnitude

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
    local targetFOV = VisionV2.Shared.ZoomEnabled and VisionV2.Shared.ZoomFOV or VisionV2.Shared.DefaultFOV
    local tween = VisionV2.Shared.TweenService:Create(VisionV2.Shared.Camera, ZoomTweenInfo, {FieldOfView = targetFOV})
    tween:Play()
end

-- Handle Zoom Key Input
local function SetupZoomInput()
    VisionV2.Shared.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == VisionV2.Shared.ZoomKey or input.KeyCode == VisionV2.Shared.ZoomKey then
            VisionV2.Shared.ZoomEnabled = true
            UpdateZoom()
        end
    end)

    VisionV2.Shared.UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == VisionV2.Shared.ZoomKey or input.KeyCode == VisionV2.Shared.ZoomKey then
            VisionV2.Shared.ZoomEnabled = false
            UpdateZoom()
        end
    end)
end

-- FOV Circle
local function CreateFOVCircle()
    local circle = Drawing.new("Circle")
    circle.Thickness = VisionV2.Shared.Settings.AimbotFOV.Thickness
    circle.NumSides = VisionV2.Shared.Settings.AimbotFOV.Sides
    circle.Radius = VisionV2.Shared.Settings.AimbotFOV.Amount
    circle.Visible = VisionV2.Shared.Settings.AimbotFOV.Visible and (VisionV2.Shared.AimbotEnabled or VisionV2.Shared.SilentAimEnabled)
    circle.Color = VisionV2.Shared.Settings.AimbotFOV.Color
    circle.Filled = VisionV2.Shared.Settings.AimbotFOV.Filled
    circle.Transparency = VisionV2.Shared.Settings.AimbotFOV.Transparency
    circle.Position = VisionV2.Shared.UserInputService:GetMouseLocation()
    return circle
end

-- Combat Tab (Aimbot Settings)
local function SetupCombatTab()
    local AimbotSection = VisionV2.Shared.CombatTab:Section({
        Name = "Aimbot Settings",
        Side = "Left"
    })

    AimbotSection:Toggle({
        Name = "Enabled",
        Flag = "Aimbot_Enabled",
        Default = VisionV2.Shared.Settings.Aimbot.Enabled,
        Callback = function(Value)
            VisionV2.Shared.AimbotEnabled = Value
            VisionV2.Shared.Settings.Aimbot.Enabled = Value
            if not Value then
                Aimbot.CancelLock()
            end
        end
    })

    AimbotSection:Toggle({
        Name = "Silent Aim",
        Flag = "Silent_Aim_Enabled",
        Default = VisionV2.Shared.SilentAimEnabled,
        Callback = function(Value)
            VisionV2.Shared.SilentAimEnabled = Value
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
        Default = VisionV2.Shared.Settings.Aimbot.ShowFOV,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Visible = Value
            if FOVCircle then
                FOVCircle.Visible = Value and (VisionV2.Shared.AimbotEnabled or VisionV2.Shared.SilentAimEnabled)
            end
        end
    })

    AimbotSection:Toggle({
        Name = "Team Check",
        Flag = "Aimbot_TeamCheck",
        Default = VisionV2.Shared.Settings.Aimbot.TeamCheck,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.TeamCheck = Value
        end
    })

    AimbotSection:Toggle({
        Name = "Alive Check",
        Flag = "Aimbot_AliveCheck",
        Default = VisionV2.Shared.Settings.Aimbot.AliveCheck,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.AliveCheck = Value
        end
    })

    AimbotSection:Toggle({
        Name = "Wall Check",
        Flag = "Aimbot_WallCheck",
        Default = VisionV2.Shared.Settings.Aimbot.WallCheck,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.WallCheck = Value
        end
    })

    AimbotSection:Toggle({
        Name = "Third Person",
        Flag = "Aimbot_ThirdPerson",
        Default = VisionV2.Shared.Settings.Aimbot.ThirdPerson,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.ThirdPerson = Value
            VisionV2.Shared.ThirdPersonEnabled = Value
            UpdateThirdPerson()
        end
    })

    AimbotSection:Toggle({
        Name = "Predict Movement",
        Flag = "Aimbot_PredictMovement",
        Default = VisionV2.Shared.Settings.Aimbot.PredictMovement,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.PredictMovement = Value
        end
    })

    AimbotSection:Keybind({
        Name = "Zoom Key",
        Flag = "Aimbot_ZoomKey",
        Default = VisionV2.Shared.ZoomKey,
        Callback = function(Keybind)
            VisionV2.Shared.ZoomKey = Keybind
        end
    })

    AimbotSection:Slider({
        Name = "FOV",
        Flag = "Aimbot_FOV",
        Default = VisionV2.Shared.Settings.AimbotFOV.Amount,
        Min = 10,
        Max = 300,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Amount = Value
            if FOVCircle then
                FOVCircle.Radius = Value
            end
        end
    })

    AimbotSection:Slider({
        Name = "Sensitivity",
        Flag = "Aimbot_Sensitivity",
        Default = VisionV2.Shared.Settings.Aimbot.Sensitivity * 100,
        Min = 0,
        Max = 100,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.Sensitivity = Value / 100
        end
    })

    AimbotSection:Slider({
        Name = "ThirdPerson Sensitivity",
        Flag = "Aimbot_ThirdPersonSensitivity",
        Default = VisionV2.Shared.Settings.Aimbot.ThirdPersonSensitivity,
        Min = 0.1,
        Max = 5,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.ThirdPersonSensitivity = Value
        end
    })

    AimbotSection:Slider({
        Name = "Bullet Speed",
        Flag = "Aimbot_BulletSpeed",
        Default = VisionV2.Shared.Settings.Aimbot.BulletSpeed,
        Min = 100,
        Max = 5000,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.BulletSpeed = Value
        end
    })

    AimbotSection:Dropdown({
        Name = "Target Part",
        Flag = "Aimbot_TargetPart",
        Content = {"Head", "HumanoidRootPart", "Torso"},
        Default = VisionV2.Shared.Settings.Aimbot.TargetPart,
        Callback = function(Value)
            VisionV2.Shared.Settings.Aimbot.TargetPart = Value
        end
    })

    local AimbotFOVSection = VisionV2.Shared.CombatTab:Section({
        Name = "Field Of View Settings",
        Side = "Right"
    })

    AimbotFOVSection:Toggle({
        Name = "Enabled",
        Flag = "AimbotFOV_Enabled",
        Default = VisionV2.Shared.Settings.AimbotFOV.Enabled,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Enabled = Value
        end
    })

    AimbotFOVSection:Toggle({
        Name = "Visible",
        Flag = "AimbotFOV_Visible",
        Default = VisionV2.Shared.Settings.AimbotFOV.Visible,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Visible = Value
            if FOVCircle then
                FOVCircle.Visible = Value and (VisionV2.Shared.AimbotEnabled or VisionV2.Shared.SilentAimEnabled)
            end
        end
    })

    AimbotFOVSection:Slider({
        Name = "Transparency",
        Flag = "AimbotFOV_Transparency",
        Default = VisionV2.Shared.Settings.AimbotFOV.Transparency * 10,
        Min = 0,
        Max = 10,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Transparency = Value / 10
            if FOVCircle then
                FOVCircle.Transparency = Value / 10
            end
        end
    })

    AimbotFOVSection:Slider({
        Name = "Sides",
        Flag = "AimbotFOV_Sides",
        Default = VisionV2.Shared.Settings.AimbotFOV.Sides,
        Min = 3,
        Max = 60,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Sides = Value
            if FOVCircle then
                FOVCircle.NumSides = Value
            end
        end
    })

    AimbotFOVSection:Slider({
        Name = "Thickness",
        Flag = "AimbotFOV_Thickness",
        Default = VisionV2.Shared.Settings.AimbotFOV.Thickness,
        Min = 1,
        Max = 5,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Thickness = Value
            if FOVCircle then
                FOVCircle.Thickness = Value
            end
        end
    })

    AimbotFOVSection:Colorpicker({
        Name = "Color",
        Flag = "AimbotFOV_Color",
        Default = VisionV2.Shared.Settings.AimbotFOV.Color,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.Color = Value
            if FOVCircle then
                FOVCircle.Color = VisionV2.Shared.CurrentTarget and VisionV2.Shared.Settings.AimbotFOV.LockedColor or Value
            end
        end
    })

    AimbotFOVSection:Colorpicker({
        Name = "Locked Color",
        Flag = "AimbotFOV_LockedColor",
        Default = VisionV2.Shared.Settings.AimbotFOV.LockedColor,
        Callback = function(Value)
            VisionV2.Shared.Settings.AimbotFOV.LockedColor = Value
        end
    })
end

function Aimbot.Init(vision)
    VisionV2 = vision
    FOVCircle = CreateFOVCircle()

    VisionV2.Shared.LocalPlayer.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        character:WaitForChild("Humanoid")
        if VisionV2.Shared.Settings.Aimbot.ThirdPerson then
            VisionV2.Shared.ThirdPersonEnabled = true
            UpdateThirdPerson()
        end
    end)

    if VisionV2.Shared.LocalPlayer.Character then
        VisionV2.Shared.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        if VisionV2.Shared.Settings.Aimbot.ThirdPerson then
            VisionV2.Shared.ThirdPersonEnabled = true
            UpdateThirdPerson()
        end
    end

    VisionV2.Shared.Camera.FieldOfView = VisionV2.Shared.DefaultFOV
    SetupZoomInput()
    SetupCombatTab()
end

function Aimbot.Update()
    if FOVCircle then
        FOVCircle.Position = VisionV2.Shared.UserInputService:GetMouseLocation()
        FOVCircle.Radius = VisionV2.Shared.Settings.AimbotFOV.Amount
        FOVCircle.Thickness = VisionV2.Shared.Settings.AimbotFOV.Thickness
        FOVCircle.Filled = VisionV2.Shared.Settings.AimbotFOV.Filled
        FOVCircle.NumSides = VisionV2.Shared.Settings.AimbotFOV.Sides
        FOVCircle.Color = VisionV2.Shared.CurrentTarget and VisionV2.Shared.Settings.AimbotFOV.LockedColor or VisionV2.Shared.Settings.AimbotFOV.Color
        FOVCircle.Transparency = VisionV2.Shared.Settings.AimbotFOV.Transparency
        FOVCircle.Visible = VisionV2.Shared.Settings.AimbotFOV.Visible and (VisionV2.Shared.AimbotEnabled or VisionV2.Shared.SilentAimEnabled)
    end
    
    HideHandsOnADS()
    
    if VisionV2.Shared.AimbotEnabled or VisionV2.Shared.SilentAimEnabled then
        VisionV2.Shared.CurrentTarget = Aimbot.GetClosestPlayer()
    end
    
    if VisionV2.Shared.AimbotRunning and VisionV2.Shared.AimbotEnabled and VisionV2.Shared.CurrentTarget and VisionV2.Shared.CurrentTarget.Character and VisionV2.Shared.CurrentTarget.Character:FindFirstChild(VisionV2.Shared.Settings.Aimbot.TargetPart) then
        if VisionV2.Shared.Settings.Aimbot.ThirdPerson then
            local Vector = VisionV2.Shared.Camera:WorldToViewportPoint(VisionV2.Shared.CurrentTarget.Character[VisionV2.Shared.Settings.Aimbot.TargetPart].Position)
            local mousePos = VisionV2.Shared.UserInputService:GetMouseLocation()
            local deltaX = (Vector.X - mousePos.X) * VisionV2.Shared.Settings.Aimbot.ThirdPersonSensitivity
            local deltaY = (Vector.Y - mousePos.Y) * VisionV2.Shared.Settings.Aimbot.ThirdPersonSensitivity
        else
            local targetPos = PredictTargetPosition(VisionV2.Shared.CurrentTarget.Character[VisionV2.Shared.Settings.Aimbot.TargetPart])
            if targetPos and VisionV2.Shared.Camera then
                if VisionV2.Shared.Settings.Aimbot.Sensitivity > 0 then
                    if VisionV2.Shared.AimbotAnimation then
                        VisionV2.Shared.AimbotAnimation:Cancel()
                    end
                    VisionV2.Shared.AimbotAnimation = VisionV2.Shared.TweenService:Create(VisionV2.Shared.Camera, TweenInfo.new(VisionV2.Shared.Settings.Aimbot.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(VisionV2.Shared.Camera.CFrame.Position, targetPos)
                    })
                    VisionV2.Shared.AimbotAnimation:Play()
                else
                    VisionV2.Shared.Camera.CFrame = CFrame.new(VisionV2.Shared.Camera.CFrame.Position, targetPos)
                end
                VisionV2.Shared.UserInputService.MouseDeltaSensitivity = 0
            end
        end
    else
        VisionV2.Shared.UserInputService.MouseDeltaSensitivity = VisionV2.Shared.OriginalSensitivity
        if VisionV2.Shared.AimbotAnimation then
            VisionV2.Shared.AimbotAnimation:Cancel()
            VisionV2.Shared.AimbotAnimation = nil
        end
    end
end

return Aimbot
