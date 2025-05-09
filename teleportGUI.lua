-- Teleport GUI (V5)
-- Features:
-- • Responsive scaling
-- • Rounded corners with UICorner
-- • Outline strokes with UIStroke
-- • Gradient backgrounds for buttons
-- • Search box to filter player list
-- • Clean spacing with UIPadding and UIListLayout
-- • Improved dragging mechanism for the window for better reliability and resource management.
-- • Toggle visibility with customizable hotkey
-- • Tabs for Player List and Hotkey Settings
-- • Added check to unanchor local player's HumanoidRootPart before teleport for robustness.
-- • Note: Client-side long-distance teleportation may be affected by game's StreamingEnabled settings; this GUI uses direct CFrame teleportation.

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
local dragStartPos = Vector2.zero -- Screen position of mouse at drag start
local frameInitialPos = UDim2.new() -- Initial UDim2 position of the mainFrame
local mouseMoveConnection = nil
local mouseUpConnection = nil

-- Current hotkey for toggling GUI visibility (default: Z)
local currentToggleHotkey = Enum.KeyCode.Z
local currentToggleHotkeyDisplay = "Z"

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTeleportGUIV5"
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
local function updateDragFramePosition(inputPosition)
	local delta = inputPosition - dragStartPos
	mainFrame.Position = UDim2.new(frameInitialPos.X.Scale, frameInitialPos.X.Offset + delta.X, frameInitialPos.Y.Scale, frameInitialPos.Y.Offset + delta.Y)
end

-- Title bar
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, 0, 0, 36)
titleContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
titleContainer.BorderSizePixel = 0
titleContainer.Parent = mainFrame

local titleCorner = frameCorner:Clone()
titleCorner.Parent = titleContainer

-- Drag events on title bar
titleContainer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStartPos = input.Position
		frameInitialPos = mainFrame.Position

		-- Disconnect old connections if they exist (safety)
		if mouseMoveConnection then mouseMoveConnection:Disconnect() end
		if mouseUpConnection then mouseUpConnection:Disconnect() end

		-- Connect to global mouse movement and release
		mouseMoveConnection = UserInputService.InputChanged:Connect(function(moveInput)
			if dragging and moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				updateDragFramePosition(moveInput.Position)
			end
		end)

		mouseUpConnection = UserInputService.InputEnded:Connect(function(endInput)
			if dragging and endInput.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				if mouseMoveConnection then
					mouseMoveConnection:Disconnect()
					mouseMoveConnection = nil
				end
				if mouseUpConnection then
					mouseUpConnection:Disconnect()
					mouseUpConnection = nil
				end
			end
		end)
	end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Teleport GUI (V5)" -- Renamed GUI
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
tabsContainer.Position = UDim2.new(0, 12, 0, 40)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = mainFrame

local tabsListLayout = Instance.new("UIListLayout")
tabsListLayout.FillDirection = Enum.FillDirection.Horizontal
tabsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsListLayout.Padding = UDim.new(0, 5)
tabsListLayout.Parent = tabsContainer

-- Content Pages Container
local contentPagesContainer = Instance.new("Frame")
contentPagesContainer.Name = "ContentPagesContainer"
contentPagesContainer.Size = UDim2.new(1, 0, 1, -82)
contentPagesContainer.Position = UDim2.new(0, 0, 0, 76)
contentPagesContainer.BackgroundTransparency = 1
contentPagesContainer.Parent = mainFrame

-- Player List Page
local playerListPage = Instance.new("Frame")
playerListPage.Name = "PlayerListPage"
playerListPage.Size = UDim2.new(1, 0, 1, 0)
playerListPage.BackgroundTransparency = 1
playerListPage.Visible = true
playerListPage.Parent = contentPagesContainer

-- Hotkeys Page
local hotkeysPage = Instance.new("Frame")
hotkeysPage.Name = "HotkeysPage"
hotkeysPage.Size = UDim2.new(1, 0, 1, 0)
hotkeysPage.BackgroundTransparency = 1
hotkeysPage.Visible = false
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
playerListTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
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
hotkeysTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
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
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.PlaceholderText = "Search players..."
searchBox.Size = UDim2.new(1, -24, 0, 32)
searchBox.Position = UDim2.new(0, 12, 0, 10)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
searchBox.TextColor3 = Color3.fromRGB(235, 235, 235)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = playerListPage
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "PlayerListScroll"
scrollingFrame.Size = UDim2.new(1, -24, 0, 260)
scrollingFrame.Position = UDim2.new(0, 12, 0, 52)
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

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Name = "SelectedPlayerLabel"
selectedLabel.Size = UDim2.new(1, -24, 0, 28)
selectedLabel.Position = UDim2.new(0, 12, 0, 322)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected: None"
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextSize = 14
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = playerListPage

local teleportBtn = Instance.new("TextButton")
teleportBtn.Name = "TeleportButton"
teleportBtn.Size = UDim2.new(1, -24, 0, 36)
teleportBtn.Position = UDim2.new(0, 12, 0, 360)
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

local playerButtons = {}

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
				btn.Size = UDim2.new(1, -8, 0, 32)
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
					for _, bItem in ipairs(scrollingFrame:GetChildren()) do
						if bItem:IsA("TextButton") then
							bItem.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
						end
					end
					btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				end)
				playerButtons[playerObj] = btn
			end
		end
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	populatePlayerTargets(searchBox.Text)
end)

teleportBtn.MouseButton1Click:Connect(function()
	if isTeleporting then return end
	if selectedPlayerTarget and humanoidRootPart then
		local targetPlayer = Players:FindFirstChild(selectedPlayerTarget.Name)
		if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			isTeleporting = true
			teleportBtn.Text = "Teleporting..."
			
			if humanoidRootPart.Anchored then -- Ensure local player HRP is not anchored
				humanoidRootPart.Anchored = false
				task.wait() -- Brief pause to allow physics to update
			end

			if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
				localPlayer.Character.Humanoid.Sit = false -- Ensure player is not seated
			end

			local targetHRP = targetPlayer.Character.HumanoidRootPart
			local dest = targetHRP.Position + Vector3.new(0, 3.5, 0) -- Slightly increased offset for safety
			humanoidRootPart.CFrame = CFrame.new(dest)
			
			task.wait(0.4)
			teleportBtn.Text = "Teleport"
			isTeleporting = false
		else
			selectedLabel.Text = "Selected: Target unavailable"
			selectedPlayerTarget = nil
		end
	else
		selectedLabel.Text = "Selected: None (choose a player)"
	end
end)

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
hotkeyStatusLabel.TextColor3 = Color3.fromRGB(150, 220, 150)
hotkeyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
hotkeyStatusLabel.Parent = hotkeysPage

hotkeyInputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local newKeyText = string.upper(hotkeyInputBox.Text)
		hotkeyInputBox.Text = "" 

		if #newKeyText == 1 and newKeyText:match("%u") then
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
		hotkeyInputBox.Text = "" 
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == currentToggleHotkey then
		local focusedTextBox = UserInputService:GetFocusedTextBox()
		if not focusedTextBox then
			mainFrame.Visible = not mainFrame.Visible
		end
	end
end)

populatePlayerTargets()
switchTab("Players")

print("Teleport GUI (V5) Loaded. Press '".. currentToggleHotkeyDisplay .."' to toggle visibility.")
