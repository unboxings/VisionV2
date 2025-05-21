-- Main.lua
-- VisionV2 by unboxings © 2025

-- Loaded Check (adapted from AirHub V2)
if VisionV2Loaded or VisionV2Loading then
    return
end

getgenv().VisionV2Loading = true

-- Cache (inspired by AirHub V2)
local game = game
local loadstring, pcall = loadstring, pcall
local wait = task.wait

-- Detect Third-Party Environment (adapted from AirHub V2)
local isThirdParty = pcall(function()
    return game:GetService("ThirdPartyUserService") ~= nil
end)
if isThirdParty then
    warn("Detected third-party environment. Some features may not work as expected. Consider testing in Roblox Studio.")
end

-- Wait for Game to Load (extended from AirHub V2 approach)
print("Waiting for game to load...")
local gameLoadTimeout = 30
local startTime = tick()
if game and game.IsLoaded then
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
else
    print("Game object not found, waiting up to " .. gameLoadTimeout .. " seconds...")
    while not game and (tick() - startTime) < gameLoadTimeout do
        wait(1)
    end
end
if not game then
    warn("Game object not available after timeout. Script will proceed with limited functionality.")
else
    print("Game loaded successfully or timeout reached!")
end

-- BASE_URL for your GitHub repository
local BASE_URL = "https://raw.githubusercontent.com/unboxings/VisionV2/main/lua/"

-- Function to load a module from a URL (same as before, inspired by AirHub V2)
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
print("Initializing Core table...")
_G.Core = {}

-- Wait for game and workspace objects to be available
print("Waiting for game and workspace objects...")
local maxWaitTime = 30
local waitTime = 0
while (not game or not workspace) and waitTime < maxWaitTime do
    print("Game or Workspace not yet available, waiting...")
    wait(0.5)
    waitTime = waitTime + 0.5
end
if not game or not workspace then
    warn("Timeout waiting for game and workspace objects. Script will proceed with limited functionality.")
end

-- Services with enhanced error handling and fallback
local success, err = pcall(function()
    if not game then
        error("Game object is nil")
    end
    local playersService = game:GetService("Players")
    if not playersService then
        warn("Players service not available. Features requiring Players service will be disabled.")
        Core.Players = nil
    else
        Core.Players = playersService
    end
    Core.UserInputService = game:GetService("UserInputService")
    Core.TweenService = game:GetService("TweenService")
    Core.RunService = game:GetService("RunService")
    Core.Camera = workspace and workspace.CurrentCamera or nil
    if not Core.Camera then
        warn("Camera not found in workspace. Features requiring Camera will be disabled.")
    end
    Core.Debris = game:GetService("Debris")
    Core.Lighting = game:GetService("Lighting")
end)

if not success then
    warn("Failed to initialize some services: " .. err .. ". Proceeding with limited functionality.")
end

print("Services initialized with possible limitations!")

-- Variables (with fallbacks for missing services)
Core.LocalPlayer = Core.Players and Core.Players.LocalPlayer or nil
if Core.Players and not Core.LocalPlayer then
    warn("LocalPlayer not found, waiting...")
    local localPlayerTimeout = 20
    local startTime = tick()
    while not Core.LocalPlayer and (tick() - startTime) < localPlayerTimeout do
        wait(0.5)
        Core.LocalPlayer = Core.Players.LocalPlayer
    end
    if not Core.LocalPlayer then
        warn("Timeout waiting for LocalPlayer. Features requiring LocalPlayer will be disabled.")
    end
end
Core.Mouse = Core.LocalPlayer and Core.LocalPlayer:GetMouse() or nil
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
Core.ZoomKey = Core.UserInputService and Enum.UserInputType.MouseButton3 or nil
Core.DefaultFOV = 70
Core.ZoomFOV = 20
Core.OriginalSensitivity = Core.UserInputService and Core.UserInputService.MouseDeltaSensitivity or 0
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

-- Utility Functions (unchanged)
function Core.CreateInstance(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

function Core.MakeDraggable(frame)
    if not Core.UserInputService or not Core.TweenService then
        warn("UserInputService or TweenService not available. Draggable functionality disabled.")
        return
    end
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

-- Load all modules (same as AirHub V2 approach)
print("Loading Aimbot module...")
local Aimbot = loadModule("Aimbot")
print("Loading Visuals module...")
local Visuals = loadModule("Visuals")
print("Loading GUI module...")
local GUI = loadModule("GUI")

-- Check if all modules loaded successfully and initialize (inspired by AirHub V2)
if Aimbot and Visuals and GUI then
    print("All modules loaded successfully!")
    if Aimbot then
        Aimbot:Enable()
    else
        warn("Aimbot module not loaded. Aimbot features disabled.")
    end
    if Visuals then
        Visuals:EnableESP()
    else
        warn("Visuals module not loaded. ESP features disabled.")
    end
    if GUI then
        GUI:CreateWindow()
    else
        warn("GUI module not loaded. Interface will not be available.")
    end
else
    warn("One or more modules failed to load. Script functionality limited.")
end

-- Initialize Zoom (with fallback)
if Core.Camera then
    Core.Camera.FieldOfView = Core.DefaultFOV
else
    warn("Camera not available, cannot set FieldOfView")
end

-- Mark script as loaded (adapted from AirHub V2)
getgenv().VisionV2Loaded = true
getgenv().VisionV2Loading = nil
