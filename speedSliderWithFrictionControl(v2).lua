--[[
    Speed Control Script (v2)

    Features:
    - GUI for controlling player WalkSpeed.
    - Draggable UI window.
    - Slider for intuitive speed adjustment.
    - Text input for setting exact speed.
    - Friction control toggle:
        - When ON, player stops immediately upon releasing movement keys (W,A,S,D).
        - When OFF, default Roblox character friction applies.
    - Configurable hotkey to toggle UI visibility.
    - Real-time clock display.
    - Smooth UI animations.
    - Speed values are always rounded to the nearest whole number for display and application.

    Recent Changes (v2):
    - Ensured all speed values (displayed on slider, main speed label, exact speed placeholder,
      and applied to Humanoid.WalkSpeed) are rounded to the nearest integer.
      This prevents decimal speeds from being shown or used.
    - Added "ON"/"OFF" text to the friction toggle button.
    - Minor UI text and font consistency improvements.
    - Improved hotkey input validation and feedback.
    - Refined friction logic for better responsiveness.
    - Added comments for better code understanding.
]]

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

-- State
local isDragging = false
local frictionEnabled = true
local hotkey = Enum.KeyCode.RightShift -- default toggle key
local character, humanoid, lastSliderSpeed = nil, nil, DEFAULT_SPEED

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedSliderGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "SpeedControlFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.1, -150) -- Initial off-screen position for animation
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,0,0,30)
titleLabel.Position = UDim2.new(0,0,0,0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60,60,60)
titleLabel.TextColor3 = Color3.fromRGB(220,220,220)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Text = "Player Speed Control"
titleLabel.Parent = mainFrame

-- Time display (updates every 30 seconds)
local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1,0,0,20)
timeLabel.Position = UDim2.new(0,0,0,30)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(200,200,200)
timeLabel.Font = Enum.Font.SourceSansItalic
timeLabel.TextSize = 14
timeLabel.Text = os.date("%I:%M %p")
timeLabel.Parent = mainFrame

-- Speed display
local speedDisplay = Instance.new("TextLabel")
speedDisplay.Size = UDim2.new(1,0,0,25)
speedDisplay.Position = UDim2.new(0,0,0,55)
speedDisplay.BackgroundTransparency = 1
speedDisplay.TextColor3 = Color3.fromRGB(200,200,200)
speedDisplay.Font = Enum.Font.SourceSans
speedDisplay.TextSize = 16
speedDisplay.Text = "Speed: "..DEFAULT_SPEED -- Initial display
speedDisplay.Parent = mainFrame

-- Slider track
local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0.9,0,0,20)
sliderTrack.Position = UDim2.new(0.05,0,0,85)
sliderTrack.BackgroundColor3 = Color3.fromRGB(30,30,30)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = mainFrame

-- Slider handle
local sliderHandle = Instance.new("TextButton")
sliderHandle.Size = UDim2.new(0,20,0,30)
sliderHandle.AnchorPoint = Vector2.new(0.5,0.5)
sliderHandle.Position = UDim2.new((DEFAULT_SPEED - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 0.5, 0) -- Initial position based on default speed
sliderHandle.BackgroundColor3 = Color3.fromRGB(0,122,204)
sliderHandle.BorderSizePixel = 1
sliderHandle.BorderColor3 = Color3.fromRGB(0,150,255)
sliderHandle.Text = tostring(DEFAULT_SPEED) -- Initial text
sliderHandle.Font = Enum.Font.SourceSans
sliderHandle.TextSize = 12
sliderHandle.TextColor3 = Color3.fromRGB(255,255,255)
sliderHandle.Parent = sliderTrack

-- Exact speed input
local exactLabel = Instance.new("TextLabel")
exactLabel.Size = UDim2.new(0.4,0,0,20)
exactLabel.Position = UDim2.new(0.05,0,0,115)
exactLabel.BackgroundTransparency = 1
exactLabel.Text = "Exact Speed:"
exactLabel.TextColor3 = Color3.fromRGB(200,200,200)
exactLabel.Font = Enum.Font.SourceSans
exactLabel.TextSize = 14
exactLabel.Parent = mainFrame

local exactBox = Instance.new("TextBox")
exactBox.Size = UDim2.new(0.5,0,0,25)
exactBox.Position = UDim2.new(0.45,0,0,110)
exactBox.PlaceholderText = tostring(DEFAULT_SPEED) -- Initial placeholder
exactBox.ClearTextOnFocus = true -- Changed to true for better UX
exactBox.Text = ""
exactBox.TextColor3 = Color3.fromRGB(255,255,255)
exactBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
exactBox.Font = Enum.Font.SourceSans
exactBox.TextSize = 14
exactBox.Parent = mainFrame

-- Friction toggle
local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0.6,0,0,20)
toggleLabel.Position = UDim2.new(0.05,0,0,145)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Friction Control"
toggleLabel.TextColor3 = Color3.fromRGB(200,200,200)
toggleLabel.Font = Enum.Font.SourceSans
toggleLabel.TextSize = 14
toggleLabel.Parent = mainFrame

local toggleSwitch = Instance.new("TextButton")
toggleSwitch.Size = UDim2.new(0,40,0,20)
toggleSwitch.Position = UDim2.new(0.65,0,0,145)
toggleSwitch.Text = frictionEnabled and "ON" or "OFF" -- Display initial state
toggleSwitch.Font = Enum.Font.SourceSansBold
toggleSwitch.TextSize = 12
toggleSwitch.TextColor3 = Color3.fromRGB(255,255,255)
toggleSwitch.BackgroundColor3 = frictionEnabled and Color3.fromRGB(0,122,204) or Color3.fromRGB(100,100,100)
toggleSwitch.Parent = mainFrame

-- Hotkey input
local hotLabel = Instance.new("TextLabel")
hotLabel.Size = UDim2.new(0.4,0,0,20)
hotLabel.Position = UDim2.new(0.05,0,0,175)
hotLabel.BackgroundTransparency = 1
hotLabel.Text = "Toggle Hotkey:"
hotLabel.TextColor3 = Color3.fromRGB(200,200,200)
hotLabel.Font = Enum.Font.SourceSans
hotLabel.TextSize = 14
hotLabel.Parent = mainFrame

local hotBox = Instance.new("TextBox")
hotBox.Size = UDim2.new(0.5,0,0,25)
hotBox.Position = UDim2.new(0.45,0,0,170)
hotBox.PlaceholderText = hotkey.Name
hotBox.ClearTextOnFocus = true -- Changed to true for better UX
hotBox.Text = ""
hotBox.TextColor3 = Color3.fromRGB(255,255,255)
hotBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
hotBox.Font = Enum.Font.SourceSans
hotBox.TextSize = 14
hotBox.Parent = mainFrame

-- Entrance animation
TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.1, 0)}):Play()

-- Utility Functions
local function roundToNearestInt(num)
    return math.floor(num + 0.5)
end

local function clampSpeed(value)
    return math.clamp(value, MIN_SPEED, MAX_SPEED)
end

local function updateHandlePosition(speedValue) -- speedValue can be decimal for accurate positioning
    local rawPct = (speedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    local pct = math.clamp(rawPct, 0, 1) -- Ensure pct is strictly between 0 and 1
    
    TweenService:Create(sliderHandle, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(pct, 0, 0.5, 0)}):Play()
    sliderHandle.Text = tostring(roundToNearestInt(speedValue)) -- Display rounded speed on handle
end

local function updateSpeed(speedValue) -- speedValue can be decimal from input source
    local s_clamped = clampSpeed(speedValue)
    local s_rounded = roundToNearestInt(s_clamped) -- Explicitly round the clamped speed

    lastSliderSpeed = s_rounded -- Store the rounded speed
    speedDisplay.Text = "Speed: " .. s_rounded -- Display the rounded speed
    exactBox.PlaceholderText = tostring(s_rounded) -- Set placeholder to rounded speed

    if humanoid then
        humanoid.WalkSpeed = s_rounded -- Apply the rounded speed to the character
    end
end

local function haltHorizontalMovement(rootPart)
    if rootPart then
        local currentVelocity = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
    end
end

-- Initial setup of speed based on DEFAULT_SPEED
updateSpeed(DEFAULT_SPEED)
updateHandlePosition(DEFAULT_SPEED)

-- Input Handlers for Slider
sliderHandle.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        sliderHandle.BackgroundColor3 = Color3.fromRGB(0,150,255) -- Highlight color
    end
end)

UserInputService.InputChanged:Connect(function(inputObject)
    if isDragging and inputObject.UserInputType == Enum.UserInputType.MouseMovement then
        local trackAbsolutePosition = sliderTrack.AbsolutePosition
        local trackAbsoluteSize = sliderTrack.AbsoluteSize
        
        local relativeMouseX = inputObject.Position.X - trackAbsolutePosition.X
        local percentage = math.clamp(relativeMouseX / trackAbsoluteSize.X, 0, 1)
        
        local newSpeed = MIN_SPEED + percentage * (MAX_SPEED - MIN_SPEED)
        
        updateHandlePosition(newSpeed) -- Update handle position with raw speed for smoothness
        updateSpeed(newSpeed)          -- Update game speed (will be rounded internally)
    end
end)

UserInputService.InputEnded:Connect(function(inputObject)
    if isDragging and inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        sliderHandle.BackgroundColor3 = Color3.fromRGB(0,122,204) -- Normal color
    end
end)

sliderTrack.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Allow clicking on the track to set speed
        local trackAbsolutePosition = sliderTrack.AbsolutePosition
        local trackAbsoluteSize = sliderTrack.AbsoluteSize
        
        local relativeMouseX = inputObject.Position.X - trackAbsolutePosition.X
        local percentage = math.clamp(relativeMouseX / trackAbsoluteSize.X, 0, 1)
        
        local newSpeedFromTrack = MIN_SPEED + percentage * (MAX_SPEED - MIN_SPEED)
        
        updateHandlePosition(newSpeedFromTrack)
        updateSpeed(newSpeedFromTrack)
    end
end)

-- Exact Speed Input Box
exactBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then -- Only update if Enter was pressed
        local inputText = exactBox.Text
        local numberValue = tonumber(inputText)
        
        if numberValue then
            updateHandlePosition(numberValue) -- Update handle based on exact input
            updateSpeed(numberValue)          -- Update game speed based on exact input
        end
        exactBox.Text = "" -- Clear text after submission
    else -- If focus is lost without pressing Enter, reset text to placeholder if empty
        if exactBox.Text == "" then
             -- Optionally, do nothing or revert to placeholder logic if needed.
             -- For now, clearing text on focus and enter submission is common.
        end
    end
end)

-- Friction Toggle Switch
toggleSwitch.MouseButton1Click:Connect(function()
    frictionEnabled = not frictionEnabled
    toggleSwitch.BackgroundColor3 = frictionEnabled and Color3.fromRGB(0,122,204) or Color3.fromRGB(100,100,100)
    toggleSwitch.Text = frictionEnabled and "ON" or "OFF"
end)

-- Hotkey Configuration Box
hotBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local keyNameInput = hotBox.Text:match("^%s*(%w+)%s*$") -- Trim whitespace and get first word
        if keyNameInput then
            local upperKeyName = keyNameInput:upper()
            if Enum.KeyCode[upperKeyName] then
                hotkey = Enum.KeyCode[upperKeyName]
                hotBox.PlaceholderText = upperKeyName -- Show the valid key name
            else
                -- Optionally, provide feedback that the key name is invalid
                hotBox.PlaceholderText = "Invalid Key"
            end
        end
        hotBox.Text = "" -- Clear text after submission
    end
end)

-- Keyboard Input for Toggling UI and Friction Effect
UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
    if gameProcessedEvent then return end -- Ignore if GUI elements already processed it

    if inputObject.UserInputType == Enum.UserInputType.Keyboard then
        if inputObject.KeyCode == hotkey then
            mainFrame.Visible = not mainFrame.Visible
            if mainFrame.Visible then -- Play "open" animation
                mainFrame.Position = UDim2.new(0.5, -150, 0.1, -150) -- Reset before animating
                TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.1, 0)}):Play()
            end
        end

        -- Friction application on movement key press
        if frictionEnabled and character and humanoid and humanoid.Health > 0 then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                if inputObject.KeyCode == Enum.KeyCode.W or
                   inputObject.KeyCode == Enum.KeyCode.A or
                   inputObject.KeyCode == Enum.KeyCode.S or
                   inputObject.KeyCode == Enum.KeyCode.D then
                    
                    haltHorizontalMovement(rootPart)
                    humanoid.WalkSpeed = lastSliderSpeed -- Re-apply speed in case it was changed
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
    if gameProcessedEvent then return end

    -- Friction application on movement key release
    if frictionEnabled and character and humanoid and humanoid.Health > 0 then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- Check if any movement keys are still pressed
            local w_down = UserInputService:IsKeyDown(Enum.KeyCode.W)
            local a_down = UserInputService:IsKeyDown(Enum.KeyCode.A)
            local s_down = UserInputService:IsKeyDown(Enum.KeyCode.S)
            local d_down = UserInputService:IsKeyDown(Enum.KeyCode.D)

            if not (w_down or a_down or s_down or d_down) then
                -- Only halt if NO movement keys are pressed
                if inputObject.KeyCode == Enum.KeyCode.W or
                   inputObject.KeyCode == Enum.KeyCode.A or
                   inputObject.KeyCode == Enum.KeyCode.S or
                   inputObject.KeyCode == Enum.KeyCode.D then
                    
                    haltHorizontalMovement(rootPart)
                    -- humanoid.WalkSpeed = 0 -- Or keep lastSliderSpeed if preferred for immediate move on next key press
                                            -- For true friction, setting to 0 on key release and no other movement key pressed is more accurate.
                                            -- However, the original script re-applied lastSliderSpeed. We'll stick to that for now.
                    humanoid.WalkSpeed = lastSliderSpeed
                end
            else
                 humanoid.WalkSpeed = lastSliderSpeed -- Ensure speed is correct if other keys still down
            end
        end
    end
end)

-- Character Setup
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    
    -- Ensure humanoid exists and apply current speed settings
    if humanoid then
        humanoid.WalkSpeed = lastSliderSpeed -- Apply the stored (rounded) speed
        
        -- Died event for humanoid if needed for cleanup or state reset
        humanoid.Died:Connect(function()
            -- Handle character death if necessary (e.g., reset some states)
        end)
    end
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

-- Update time label periodically
coroutine.wrap(function()
    while true do
        timeLabel.Text = os.date("%I:%M %p")
        wait(30) -- Update every 30 seconds
    end
end)()

-- Parent GUI to PlayerGui
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
print("Speed Control Script (v2): Refined version loaded!")
