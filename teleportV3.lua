-- Improved Player Teleport GUI (v3)
-- Features:
-- • Responsive scaling
-- • Rounded corners with UICorner
-- • Outline strokes with UIStroke
-- • Gradient backgrounds for buttons
-- • Search box to filter player list
-- • Clean spacing with UIPadding and UIListLayout
-- • Draggable window by title bar
-- • Toggle visibility with 'Z' hotkey

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local selectedPlayerTarget = nil
local isTeleporting = false

-- State for dragging
local dragging = false
local dragInput, dragStart, startPos

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTeleportGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main container frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 320, 0, 450)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

-- Rounded corners
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

-- Outline stroke
local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(60, 60, 60)
frameStroke.Parent = mainFrame

-- Dragging update function
local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

-- Title bar
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, 0, 0, 36)
titleContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
titleContainer.BorderSizePixel = 0
titleContainer.Parent = mainFrame

local titleCorner = frameCorner:Clone()
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleContainer

-- Drag events on title bar
titleContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Teleport to Player"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.Parent = titleContainer

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.Parent = titleContainer
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Search box
local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search players..."
searchBox.Size = UDim2.new(1, -24, 0, 32)
searchBox.Position = UDim2.new(0, 12, 0, 46)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
searchBox.TextColor3 = Color3.fromRGB(235, 235, 235)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

-- Player list scrolling frame
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -24, 0, 260)
scrollingFrame.Position = UDim2.new(0, 12, 0, 90)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = mainFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = scrollingFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 6)
uiListLayout.Parent = scrollingFrame

-- Selected target label
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -24, 0, 28)
selectedLabel.Position = UDim2.new(0, 12, 0, 360)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected: None"
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextSize = 14
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = mainFrame

-- Teleport button
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, -24, 0, 36)
teleportBtn.Position = UDim2.new(0, 12, 0, 402)
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 136)
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "Teleport"
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 16
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Parent = mainFrame

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 8)
teleportCorner.Parent = teleportBtn

local buttonGradient = Instance.new("UIGradient")
buttonGradient.Color = ColorSequence.new(
    Color3.fromRGB(0, 190, 152),
    Color3.fromRGB(0, 150, 136)
)
buttonGradient.Parent = teleportBtn

-- Store buttons
local playerButtons = {}

-- Function to refresh player list with optional filter
local function populatePlayerTargets(filter)
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    table.clear(playerButtons)

    for i, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj ~= localPlayer then
            local name = playerObj.DisplayName .. " ("..playerObj.Name..")"
            if not filter or string.find(string.lower(name), string.lower(filter), 1, true) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 32)
                btn.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
                btn.BorderSizePixel = 0
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.TextColor3 = Color3.fromRGB(220, 220, 220)
                btn.Text = name
                btn.LayoutOrder = i
                btn.Parent = scrollingFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    selectedPlayerTarget = playerObj
                    selectedLabel.Text = "Selected: "..playerObj.DisplayName
                    for _, b in ipairs(scrollingFrame:GetChildren()) do
                        if b:IsA("TextButton") then
                            b.BackgroundColor3 = Color3.fromRGB(48,48,54)
                        end
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                end)

                playerButtons[playerObj] = btn
            end
        end
    end
end

-- Search filtering
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    populatePlayerTargets(searchBox.Text)
end)

-- Teleport logic
teleportBtn.MouseButton1Click:Connect(function()
    if isTeleporting then return end
    if selectedPlayerTarget and humanoidRootPart then
        local target = Players:FindFirstChild(selectedPlayerTarget.Name)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            isTeleporting = true
            teleportBtn.Text = "Teleporting..."
            local dest = target.Character.HumanoidRootPart.Position + Vector3.new(0,3,0)
            humanoidRootPart.CFrame = CFrame.new(dest)
            wait(0.4)
            teleportBtn.Text = "Teleport"
            isTeleporting = false
        else
            selectedLabel.Text = "Selected: Target unavailable"
        end
    else
        selectedLabel.Text = "Selected: None (choose a player)"
    end
end)

-- Refresh list on join/leave
Players.PlayerAdded:Connect(function() populatePlayerTargets(searchBox.Text) end)
Players.PlayerRemoving:Connect(function(player) if selectedPlayerTarget == player then selectedPlayerTarget = nil end populatePlayerTargets(searchBox.Text) end)

-- Toggle visibility with 'Z' hotkey
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Initial populate
populatePlayerTargets()
