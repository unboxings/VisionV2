-- Main.lua
local HttpService = game:GetService("HttpService")

-- BASE_URL for your GitHub repository
local BASE_URL = "https://raw.githubusercontent.com/unboxings/VisionV2/main/lua/"

-- Function to load a module from a URL
local function loadModule(moduleName)
    local url = BASE_URL .. moduleName .. ".lua"
    print("Attempting to load module: " .. moduleName .. " from " .. url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        print("Successfully fetched " .. moduleName)
        local func, err = loadstring(result)
        if func then
            print("Successfully compiled " .. moduleName)
            return func()
        else
            warn("Failed to compile " .. moduleName .. ": " .. err)
        end
    else
        warn("Failed to fetch " .. moduleName .. ": " .. result)
    end
    return nil
end

-- Create a global Core table to hold shared variables
_G.Core = {}

-- Services
Core.Players = game:GetService("Players")
Core.UserInputService = game:GetService("UserInputService")
Core.TweenService = game:GetService("TweenService")
Core.RunService = game:GetService("RunService")
Core.Camera = workspace.CurrentCamera
Core.Debris = game:GetService("Debris")
Core.Lighting = game:GetService("Lighting")

-- Variables
Core.LocalPlayer = Core.Players.LocalPlayer
Core.Mouse = Core.LocalPlayer:GetMouse()
Core.Toggled = true
Core.ESPEnabled = false
Core.FOVCircle = nil
Core.AimbotEnabled = false
Core.SilentAimEnabled = false
Core.BulletTracersEnabled = false
Core.TargetDot = nil
Core.ActiveTracers = 0
Core.MaxTracers = 10
Core.ThirdPersonEnabled = false
Core.ZoomEnabled = false
Core.ZoomKey = Enum.UserInputType.MouseButton3
Core.DefaultFOV = 70
Core.ZoomFOV = 20
Core.OriginalSensitivity = Core.UserInputService.MouseDeltaSensitivity
Core.CurrentTarget = nil
Core.AimbotRunning = false
Core.AimbotAnimation = nil

Core.Settings = {
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
Core.FONT = Enum.Font.GothamBold
Core.PRIMARY_COLOR = Color3.fromRGB(40, 40, 50)
Core.SECONDARY_COLOR = Color3.fromRGB(50, 50, 60)
Core.ACCENT_COLOR = Color3.fromRGB(255, 182, 193)
Core.TEXT_COLOR = Color3.fromRGB(255, 255, 255)
Core.SECONDARY_TEXT_COLOR = Color3.fromRGB(180, 180, 195)
Core.SHADOW_COLOR = Color3.fromRGB(20, 20, 25)
Core.TOGGLE_ON_COLOR = Color3.fromRGB(255, 182, 193)
Core.TOGGLE_OFF_COLOR = Color3.fromRGB(60, 60, 80)
Core.OUTLINE_COLOR = Color3.fromRGB(255, 182, 193)

-- Sky Color Presets
Core.SkyColors = {
    Default = {SkyColor = nil, Ambient = nil},
    Pink = {SkyColor = Color3.fromRGB(255, 182, 193), Ambient = Color3.fromRGB(255, 192, 203)},
    Sunset = {SkyColor = Color3.fromRGB(255, 147, 79), Ambient = Color3.fromRGB(200, 100, 50)},
    Night = {SkyColor = Color3.fromRGB(25, 25, 50), Ambient = Color3.fromRGB(20, 20, 30)},
    Purple = {SkyColor = Color3.fromRGB(147, 112, 219), Ambient = Color3.fromRGB(100, 80, 150)}
}

-- Materials for Chams and Hand Chams
Core.Materials = {"Neon", "ForceField", "Glass", "SmoothPlastic"}

-- Utility Functions
function Core.CreateInstance(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

function Core.MakeDraggable(frame)
    local dragToggle = nil
    local dragSpeed = 0.1
    local dragStart = nil
    local startPos = nil

    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        Core.TweenService:Create(frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
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

function Core.ConvertVector(Vector)
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
Core.Camera.FieldOfView = Core.DefaultFOV
