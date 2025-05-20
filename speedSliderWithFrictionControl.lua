-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Player reference
local localPlayer = Players.LocalPlayer
if not localPlayer then
    Players.LocalPlayerAdded:Wait()
    localPlayer = Players.LocalPlayer
end

-- Speed limits constants
local MIN_SPEED = 0
local MAX_SPEED = 5000
local DEFAULT_SPEED = 16 -- Default Roblox WalkSpeed

-- Set up ScreenGui container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedSliderGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Main frame (initially off-screen for opening animation)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "SpeedControlFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 120)
mainFrame.Position = UDim2.new(0.5, -150, 0.1, -150) -- off-screen Y
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
mainFrame.Active = true      -- allow drag
mainFrame.Draggable = true   -- make UI movable
mainFrame.Parent = screenGui

-- Title bar label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Text = "Player Speed Control"
titleLabel.Parent = mainFrame

-- Time display (just as a UI flair)
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(1, 0, 0, 20)
timeLabel.Position = UDim2.new(0, 0, 0, 30)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timeLabel.Font = Enum.Font.SourceSansItalic
timeLabel.TextSize = 14
timeLabel.Text = os.date("%I:%M %p")
timeLabel.Parent = mainFrame

-- Speed readout below title
local speedDisplayLabel = Instance.new("TextLabel")
speedDisplayLabel.Name = "SpeedDisplayLabel"
speedDisplayLabel.Size = UDim2.new(1, 0, 0, 25)
speedDisplayLabel.Position = UDim2.new(0, 0, 0, 55)
speedDisplayLabel.BackgroundTransparency = 1
speedDisplayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedDisplayLabel.Font = Enum.Font.SourceSans
speedDisplayLabel.TextSize = 16
speedDisplayLabel.Text = "Speed: " .. DEFAULT_SPEED
speedDisplayLabel.Parent = mainFrame

-- Slider track and handle
local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(0.9, 0, 0, 20)
sliderTrack.Position = UDim2.new(0.05, 0, 0, 85)
sliderTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = mainFrame

local sliderHandle = Instance.new("TextButton")
sliderHandle.Name = "SliderHandle"
sliderHandle.Size = UDim2.new(0, 20, 0, 30)
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.Position = UDim2.new(0, 0, 0.5, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
sliderHandle.BorderSizePixel = 1
sliderHandle.BorderColor3 = Color3.fromRGB(0, 150, 255)
sliderHandle.TextColor3 = Color3.fromRGB(255,255,255)
sliderHandle.Font = Enum.Font.SourceSansBold
sliderHandle.TextSize = 12
sliderHandle.Text = ""
sliderHandle.AutoButtonColor = false
sliderHandle.Parent = sliderTrack

-- Internal state
local isDragging = false
local character, humanoid
local lastSliderSpeed = DEFAULT_SPEED

-- Entrance animation tween
local entranceTween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -150, 0.1, 0)
})
entranceTween:Play()

-- Utility to clamp speed within bounds
local function clampSpeed(v)
    return math.clamp(v, MIN_SPEED, MAX_SPEED)
end

-- Smoothly update slider handle position and label
local function updateHandlePosition(speed)
    local pct = (speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    local targetPos = UDim2.new(pct, 0, 0.5, 0)
    TweenService:Create(sliderHandle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
    sliderHandle.Text = string.format("%.0f", speed)
end

-- Update actual speed on the Humanoid and display label
local function updateSpeed(speed)
    local s = clampSpeed(speed)
    lastSliderSpeed = s
    speedDisplayLabel.Text = "Speed: " .. string.format("%.0f", s)
    if humanoid then
        humanoid.WalkSpeed = s
    end
end

-- Function to halt horizontal movement (preserves vertical velocity)
local function haltHorizontal(rootPart)
    local vel = rootPart.AssemblyLinearVelocity
    rootPart.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
end

-- General input-began handler for friction control on S, A, D keys
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not character or not humanoid then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Check for S, A, or D press
    if input.KeyCode == Enum.KeyCode.S 
       or input.KeyCode == Enum.KeyCode.A 
       or input.KeyCode == Enum.KeyCode.D then
        -- Halt any sliding momentum
        haltHorizontal(rootPart)
        -- Ensure next movement uses slider-defined speed
        humanoid.WalkSpeed = lastSliderSpeed
    end
end)

-- General input-ended handler: if all horizontal movement keys released, halt
UserInputService.InputEnded:Connect(function(input, processed)
    if processed then return end
    if not character or not humanoid then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Only halt when no other movement keys remain pressed
    local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local a = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local d = UserInputService:IsKeyDown(Enum.KeyCode.D)
    if not w and not a and not s and not d then
        haltHorizontal(rootPart)
    end
    -- Reset WalkSpeed in case it was modified
    humanoid.WalkSpeed = lastSliderSpeed
end)

-- Slider drag logic
sliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos, size = sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize
        local relX = math.clamp(input.Position.X - pos.X, 0, size.X)
        local newPct = relX / size.X
        local newSpeed = MIN_SPEED + newPct * (MAX_SPEED - MIN_SPEED)
        updateHandlePosition(newSpeed)
        updateSpeed(newSpeed)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
    end
end)

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos, size = sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize
        local relX = math.clamp(input.Position.X - pos.X, 0, size.X)
        local pct = relX / size.X
        local spd = MIN_SPEED + pct * (MAX_SPEED - MIN_SPEED)
        updateHandlePosition(spd)
        updateSpeed(spd)
    end
end)

-- Character setup to reapply speed after respawn
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = lastSliderSpeed
end
Players.LocalPlayer.CharacterAdded:Connect(setupCharacter)
if Players.LocalPlayer.Character then setupCharacter(Players.LocalPlayer.Character) end

-- Parent GUI to PlayerGui
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
print("SpeedSliderGUI: Loaded with animations, draggable UI, and friction control on A/D/S keys.")
