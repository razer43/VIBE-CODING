-- Teleport GUI (V4)
-- Features:
-- • Responsive scaling
-- • Rounded corners with UICorner
-- • Outline strokes with UIStroke
-- • Gradient backgrounds for buttons
-- • Search box to filter player list
-- • Clean spacing with UIPadding and UIListLayout
-- • Draggable window by title bar
-- • Toggle visibility with customizable hotkey
-- • Tabs for Player List and Hotkey Settings

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

-- Current hotkey for toggling GUI visibility (default: Z)
local currentToggleHotkey = Enum.KeyCode.Z
local currentToggleHotkeyDisplay = "Z"

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTeleportGUIV4"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main container frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 340, 0, 520) -- Increased height for tabs and hotkey section
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

-- Rounded corners for main frame
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

-- Outline stroke for main frame
local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(60, 60, 60)
frameStroke.Parent = mainFrame

-- Dragging update function
local function updateDrag(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

-- Title bar
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, 0, 0, 36)
titleContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
titleContainer.BorderSizePixel = 0
titleContainer.Parent = mainFrame

local titleCorner = frameCorner:Clone() -- Re-use UICorner for top corners
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

-- Connect to UserInputService.InputChanged for smoother dragging
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Teleport GUI (V4)" -- Renamed GUI
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleContainer

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
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

-- Tabs Container
local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "TabsContainer"
tabsContainer.Size = UDim2.new(1, -24, 0, 30)
tabsContainer.Position = UDim2.new(0, 12, 0, 40) -- Position below title bar
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = mainFrame

local tabsListLayout = Instance.new("UIListLayout")
tabsListLayout.FillDirection = Enum.FillDirection.Horizontal
tabsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsListLayout.Padding = UDim.new(0, 5)
tabsListLayout.Parent = tabsContainer

-- Content Pages Container (holds different tab contents)
local contentPagesContainer = Instance.new("Frame")
contentPagesContainer.Name = "ContentPagesContainer"
contentPagesContainer.Size = UDim2.new(1, 0, 1, -82) -- Adjusted size: 36 (title) + 30 (tabs) + 10 (padding) + 6 (bottom margin)
contentPagesContainer.Position = UDim2.new(0, 0, 0, 76) -- Position below tabs
contentPagesContainer.BackgroundTransparency = 1
contentPagesContainer.Parent = mainFrame

-- Player List Page
local playerListPage = Instance.new("Frame")
playerListPage.Name = "PlayerListPage"
playerListPage.Size = UDim2.new(1, 0, 1, 0)
playerListPage.BackgroundTransparency = 1
playerListPage.Visible = true -- Default visible tab
playerListPage.Parent = contentPagesContainer

-- Hotkeys Page
local hotkeysPage = Instance.new("Frame")
hotkeysPage.Name = "HotkeysPage"
hotkeysPage.Size = UDim2.new(1, 0, 1, 0)
hotkeysPage.BackgroundTransparency = 1
hotkeysPage.Visible = false -- Hidden by default
hotkeysPage.Parent = contentPagesContainer

local hotkeysPagePadding = Instance.new("UIPadding")
hotkeysPagePadding.PaddingTop = UDim.new(0, 10)
hotkeysPagePadding.PaddingLeft = UDim.new(0, 12)
hotkeysPagePadding.PaddingRight = UDim.new(0, 12)
hotkeysPagePadding.Parent = hotkeysPage

local hotkeysListLayout = Instance.new("UIListLayout")
hotkeysListLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotkeysListLayout.Padding = UDim.new(0, 10)
hotkeysListLayout.Parent = hotkeysPage


-- Tab Buttons
local playerListTabButton = Instance.new("TextButton")
playerListTabButton.Name = "PlayerListTab"
playerListTabButton.Size = UDim2.new(0, 100, 1, 0)
playerListTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50) -- Active tab color
playerListTabButton.Text = "Players"
playerListTabButton.Font = Enum.Font.GothamBold
playerListTabButton.TextSize = 14
playerListTabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
playerListTabButton.LayoutOrder = 1
playerListTabButton.Parent = tabsContainer
local playerListTabCorner = Instance.new("UICorner")
playerListTabCorner.CornerRadius = UDim.new(0, 6)
playerListTabCorner.Parent = playerListTabButton

local hotkeysTabButton = Instance.new("TextButton")
hotkeysTabButton.Name = "HotkeysTab"
hotkeysTabButton.Size = UDim2.new(0, 100, 1, 0)
hotkeysTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40) -- Inactive tab color
hotkeysTabButton.Text = "Hotkeys"
hotkeysTabButton.Font = Enum.Font.Gotham
hotkeysTabButton.TextSize = 14
hotkeysTabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
hotkeysTabButton.LayoutOrder = 2
hotkeysTabButton.Parent = tabsContainer
local hotkeysTabCorner = Instance.new("UICorner")
hotkeysTabCorner.CornerRadius = UDim.new(0, 6)
hotkeysTabCorner.Parent = hotkeysTabButton

-- Function to switch tabs
local function switchTab(tabName)
	if tabName == "Players" then
		playerListPage.Visible = true
		hotkeysPage.Visible = false
		playerListTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		playerListTabButton.Font = Enum.Font.GothamBold
		hotkeysTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		hotkeysTabButton.Font = Enum.Font.Gotham
	elseif tabName == "Hotkeys" then
		playerListPage.Visible = false
		hotkeysPage.Visible = true
		hotkeysTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		hotkeysTabButton.Font = Enum.Font.GothamBold
		playerListTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		playerListTabButton.Font = Enum.Font.Gotham
	end
end

playerListTabButton.MouseButton1Click:Connect(function() switchTab("Players") end)
hotkeysTabButton.MouseButton1Click:Connect(function() switchTab("Hotkeys") end)


-- Player List Page Content
-- Search box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.PlaceholderText = "Search players..." -- Changed to "Search players..."
searchBox.Size = UDim2.new(1, -24, 0, 32)
searchBox.Position = UDim2.new(0, 12, 0, 10) -- Adjusted position within playerListPage
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
searchBox.TextColor3 = Color3.fromRGB(235, 235, 235)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = playerListPage
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

-- Player list scrolling frame
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "PlayerListScroll"
scrollingFrame.Size = UDim2.new(1, -24, 0, 260) -- Adjust size as needed
scrollingFrame.Position = UDim2.new(0, 12, 0, 52) -- Position below searchBox
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = playerListPage

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
selectedLabel.Name = "SelectedPlayerLabel"
selectedLabel.Size = UDim2.new(1, -24, 0, 28)
selectedLabel.Position = UDim2.new(0, 12, 0, 322) -- Position below scrollingFrame
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected: None"
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextSize = 14
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = playerListPage

-- Teleport button
local teleportBtn = Instance.new("TextButton")
teleportBtn.Name = "TeleportButton"
teleportBtn.Size = UDim2.new(1, -24, 0, 36)
teleportBtn.Position = UDim2.new(0, 12, 0, 360) -- Position below selectedLabel
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 136)
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "Teleport"
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 16
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Parent = playerListPage

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
			local name = playerObj.DisplayName .. " (" .. playerObj.Name .. ")"
			if not filter or filter == "" or string.find(string.lower(name), string.lower(filter), 1, true) then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -8, 0, 32) -- Adjusted for padding in scrolling frame
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
					selectedLabel.Text = "Selected: " .. playerObj.DisplayName
					for _, b in ipairs(scrollingFrame:GetChildren()) do
						if b:IsA("TextButton") then
							b.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
						end
					end
					btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100) -- Highlight selected
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
			local dest = target.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
			humanoidRootPart.CFrame = CFrame.new(dest)
			task.wait(0.4) -- Use task.wait for modern practice
			teleportBtn.Text = "Teleport"
			isTeleporting = false
		else
			selectedLabel.Text = "Selected: Target unavailable"
			selectedPlayerTarget = nil -- Clear selection if target is bad
		end
	else
		selectedLabel.Text = "Selected: None (choose a player)"
	end
end)

-- Refresh list on join/leave
Players.PlayerAdded:Connect(function() populatePlayerTargets(searchBox.Text) end)
Players.PlayerRemoving:Connect(function(player)
	if selectedPlayerTarget == player then
		selectedPlayerTarget = nil
		selectedLabel.Text = "Selected: None"
	end
	populatePlayerTargets(searchBox.Text)
end)


-- Hotkeys Page Content
local hotkeyInfoLabel = Instance.new("TextLabel")
hotkeyInfoLabel.Name = "HotkeyInfoLabel"
hotkeyInfoLabel.Size = UDim2.new(1, -24, 0, 40)
hotkeyInfoLabel.BackgroundTransparency = 1
hotkeyInfoLabel.Text = "Current toggle hotkey: " .. currentToggleHotkeyDisplay .. "\n(Press a single key to change)"
hotkeyInfoLabel.Font = Enum.Font.Gotham
hotkeyInfoLabel.TextSize = 14
hotkeyInfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hotkeyInfoLabel.TextWrapped = true
hotkeyInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
hotkeyInfoLabel.Parent = hotkeysPage

local hotkeyInputBox = Instance.new("TextBox")
hotkeyInputBox.Name = "HotkeyInputBox"
hotkeyInputBox.PlaceholderText = "Press a key..."
hotkeyInputBox.Size = UDim2.new(1, -24, 0, 32)
hotkeyInputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
hotkeyInputBox.TextColor3 = Color3.fromRGB(235, 235, 235)
hotkeyInputBox.Font = Enum.Font.Gotham
hotkeyInputBox.TextSize = 14
hotkeyInputBox.ClearTextOnFocus = true
hotkeyInputBox.Parent = hotkeysPage
local hotkeyInputCorner = Instance.new("UICorner")
hotkeyInputCorner.CornerRadius = UDim.new(0, 8)
hotkeyInputCorner.Parent = hotkeyInputBox

local hotkeyStatusLabel = Instance.new("TextLabel")
hotkeyStatusLabel.Name = "HotkeyStatusLabel"
hotkeyStatusLabel.Size = UDim2.new(1, -24, 0, 20)
hotkeyStatusLabel.BackgroundTransparency = 1
hotkeyStatusLabel.Text = ""
hotkeyStatusLabel.Font = Enum.Font.Gotham
hotkeyStatusLabel.TextSize = 12
hotkeyStatusLabel.TextColor3 = Color3.fromRGB(150, 220, 150) -- Green for success, or red for error
hotkeyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
hotkeyStatusLabel.Parent = hotkeysPage

-- Capture key press for hotkey input
hotkeyInputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then -- Usually means submitted by pressing Enter
		local newKeyText = string.upper(hotkeyInputBox.Text)
		hotkeyInputBox.Text = "" -- Clear the box

		if #newKeyText == 1 and newKeyText:match("%u") then -- Check if it's a single uppercase letter
			local success, newKeyCode = pcall(function() return Enum.KeyCode[newKeyText] end)
			if success and newKeyCode then
				currentToggleHotkey = newKeyCode
				currentToggleHotkeyDisplay = newKeyText
				hotkeyInfoLabel.Text = "Current toggle hotkey: " .. currentToggleHotkeyDisplay .. "\n(Press a single key to change)"
				hotkeyStatusLabel.Text = "Hotkey updated to: " .. currentToggleHotkeyDisplay
				hotkeyStatusLabel.TextColor3 = Color3.fromRGB(150, 220, 150)
			else
				hotkeyStatusLabel.Text = "Invalid key. Please use a single letter (A-Z)."
				hotkeyStatusLabel.TextColor3 = Color3.fromRGB(220, 150, 150)
			end
		elseif newKeyText ~= "" then
			hotkeyStatusLabel.Text = "Invalid input. Please press a single letter key."
			hotkeyStatusLabel.TextColor3 = Color3.fromRGB(220, 150, 150)
		end
	else
		hotkeyInputBox.Text = "" -- Clear if focus lost without enter (e.g. click away)
	end
end)


-- Toggle visibility with current hotkey
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == currentToggleHotkey then
		-- Check if a TextBox is focused to prevent toggling while typing
		local focusedTextBox = UserInputService:GetFocusedTextBox()
		if not focusedTextBox then
			mainFrame.Visible = not mainFrame.Visible
		end
	end
end)

-- Initial populate of player list
populatePlayerTargets()

-- Initial tab setup
switchTab("Players") -- Make sure player list is shown first

print("Teleport GUI (V4) Loaded. Press '".. currentToggleHotkeyDisplay .."' to toggle visibility.")
