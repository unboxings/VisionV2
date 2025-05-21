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
DateTimePopup.Text = "Today's date and time is 10:27 AM PDT on Wednesday, May 21, 2025"
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

-- Shared Variables and Functions for Other Modules
VisionV2 = {
    UI = MainFrame,
    Toggle = function(visible)
        MainFrame.MainFrame.Visible = visible
        Toggled = visible
    end,
    GetToggleState = function()
        return Toggled
    end,
    Shared = {
        Players = Players,
        UserInputService = UserInputService,
        TweenService = TweenService,
        RunService = RunService,
        Camera = Camera,
        Debris = Debris,
        Lighting = Lighting,
        LocalPlayer = LocalPlayer,
        Mouse = Mouse,
        Toggled = Toggled,
        ESPEnabled = ESPEnabled,
        AimbotEnabled = AimbotEnabled,
        SilentAimEnabled = SilentAimEnabled,
        BulletTracersEnabled = BulletTracersEnabled,
        TargetDot = TargetDot,
        ActiveTracers = ActiveTracers,
        MaxTracers = MaxTracers,
        ThirdPersonEnabled = ThirdPersonEnabled,
        ZoomEnabled = ZoomEnabled,
        ZoomKey = ZoomKey,
        DefaultFOV = DefaultFOV,
        ZoomFOV = ZoomFOV,
        OriginalSensitivity = OriginalSensitivity,
        CurrentTarget = CurrentTarget,
        AimbotRunning = AimbotRunning,
        AimbotAnimation = AimbotAnimation,
        Settings = Settings,
        SkyColors = SkyColors,
        Materials = Materials,
        ConvertVector = ConvertVector,
        CombatTab = Combat,
        CombatSignal = CombatSignal,
        VisualsTab = Visuals,
        MiscTab = Misc,
        SettingsTab = SettingsTab
    }
}

-- Load Other Modules
local Aimbot = require(script.Parent.Aimbot)
local Visuals = require(script.Parent.Visuals)

-- Initialize Modules
Aimbot.Init(VisionV2)
Visuals.Init(VisionV2)

-- Optimized Render Loop
local lastUpdate = tick()
local updateInterval = 1/30

RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick()
    if currentTime - lastUpdate < updateInterval then return end
    lastUpdate = currentTime

    -- Update shared variables
    VisionV2.Shared.ESPEnabled = ESPEnabled
    VisionV2.Shared.AimbotEnabled = AimbotEnabled
    VisionV2.Shared.SilentAimEnabled = SilentAimEnabled
    VisionV2.Shared.BulletTracersEnabled = BulletTracersEnabled
    VisionV2.Shared.TargetDot = TargetDot
    VisionV2.Shared.ActiveTracers = ActiveTracers
    VisionV2.Shared.ThirdPersonEnabled = ThirdPersonEnabled
    VisionV2.Shared.ZoomEnabled = ZoomEnabled
    VisionV2.Shared.ZoomKey = ZoomKey
    VisionV2.Shared.CurrentTarget = CurrentTarget
    VisionV2.Shared.AimbotRunning = AimbotRunning
    VisionV2.Shared.AimbotAnimation = AimbotAnimation

    Aimbot.Update()
    Visuals.Update()
end)

-- Optimized Heartbeat Loop
local lastChamsRefresh = tick()
local chamsRefreshInterval = 5

RunService.Heartbeat:Connect(function()
    Visuals.ScanPlayers()
    
    local currentTime = tick()
    if currentTime - lastChamsRefresh >= chamsRefreshInterval and Settings.Visuals.Chams then
        Visuals.RefreshChams()
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
        VisionV2.Shared.AimbotRunning = AimbotRunning
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not Typing and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotRunning = false
        VisionV2.Shared.AimbotRunning = AimbotRunning
        if AimbotEnabled then
            Aimbot.CancelLock()
        end
    end
end)

-- Finalize Initialization
VisionV2.Shared.CombatSignal:Fire()
MainFrame.MainFrame.Visible = true

return VisionV2
