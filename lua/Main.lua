-- Main.lua
local HttpService = game:GetService("HttpService")

-- Replace with your GitHub repository's raw base URL
local BASE_URL = "https://raw.githubusercontent.com/YourUsername/YourRepo/main/"

-- Function to load a module from a URL
local function loadModule(moduleName)
    local url = BASE_URL .. moduleName .. ".lua"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        local func, err = loadstring(result)
        if func then
            return func()
        else
            warn("Failed to load " .. moduleName .. ": " .. err)
        end
    else
        warn("Failed to fetch " .. moduleName .. ": " .. result)
    end
    return nil
end

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
        ESPEnabled = false,
        Box = false,
        Name = false,
        Distance = false,
        Health = false,
        Weapon = false,
        Skeleton = false,
        TeamCheck = true,
        EnemyColor = Color3.fromRGB(255, 182, 193),
        TeamColor = Color3.fromRGB(255, 192, 203),
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

-- Load all modules
local Aimbot = loadModule("Aimbot")
local Visuals = loadModule("Visuals")
local GUI = loadModule("GUI")

-- Check if all modules loaded successfully
if Aimbot and Visuals and GUI then
    print("All modules loaded successfully!")
    Aimbot:Enable()
    Visuals:EnableESP()
    GUI:CreateWindow()
else
    warn("One or more modules failed to load.")
end

-- Initialize Zoom
Camera.FieldOfView = DefaultFOV