local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")


local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local IS_DESKTOP = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled

-- Configuration
local FLY_SPEED = 50
local VERTICAL_SPEED = 50
local TOGGLE_KEY = Enum.KeyCode.F
local UP_KEY = Enum.KeyCode.Space
local DOWN_KEY = Enum.KeyCode.LeftShift


local gui = Instance.new("ScreenGui")
gui.Name = "FlyGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true


local mobileControls = Instance.new("Frame")
mobileControls.Name = "MobileControls"
mobileControls.Size = UDim2.new(1, 0, 1, 0)
mobileControls.BackgroundTransparency = 1
mobileControls.Visible = IS_MOBILE
mobileControls.Parent = gui

-- Joystick
local joystickFrame = Instance.new("Frame")
joystickFrame.Name = "JoystickFrame"
joystickFrame.Size = UDim2.new(0.3, 0, 0.3, 0)
joystickFrame.Position = UDim2.new(0.1, 0, 0.6, 0)
joystickFrame.BackgroundTransparency = 0.8
joystickFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
joystickFrame.BorderSizePixel = 0
joystickFrame.AnchorPoint = Vector2.new(0, 0.5)
joystickFrame.Parent = mobileControls

local joystickInner = Instance.new("Frame")
joystickInner.Name = "JoystickInner"
joystickInner.Size = UDim2.new(0.4, 0, 0.4, 0)
joystickInner.Position = UDim2.new(0.3, 0, 0.3, 0)
joystickInner.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
joystickInner.BorderSizePixel = 0
joystickInner.Parent = joystickFrame

-- PC Controls
local pcControls = Instance.new("Frame")
pcControls.Name = "PCControls"
pcControls.Size = UDim2.new(0.25, 0, 0.1, 0)
pcControls.Position = UDim2.new(0.75, 0, 0.05, 0)
pcControls.BackgroundTransparency = 0.8
pcControls.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
pcControls.Visible = IS_DESKTOP
pcControls.Parent = gui


local pcText = Instance.new("TextLabel")
pcText.Name = "PCText"
pcText.Size = UDim2.new(1, 0, 1, 0)
pcText.BackgroundTransparency = 1
pcText.Text = "FLY: F | WASD: Move | SPACE: Up | SHIFT: Down"
pcText.TextColor3 = Color3.new(1, 1, 1)
pcText.TextScaled = true
pcText.Font = Enum.Font.GothamBold
pcText.TextXAlignment = Enum.TextXAlignment.Center
pcText.TextYAlignment = Enum.TextYAlignment.Center
pcText.Parent = pcControls


local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.3, 0, 0.1, 0)
toggleButton.Position = UDim2.new(0.8, 0, 0.8, 0)
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
toggleButton.Text = "✈️ FLY (OFF)"
toggleButton.TextScaled = true
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Visible = IS_MOBILE
toggleButton.Parent = mobileControls


local upButton = Instance.new("TextButton")
upButton.Name = "UpButton"
upButton.Size = UDim2.new(0.15, 0, 0.1, 0)
upButton.Position = UDim2.new(0.8, 0, 0.65, 0)
upButton.AnchorPoint = Vector2.new(0.5, 0.5)
upButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
upButton.Text = "▲"
upButton.TextScaled = true
upButton.TextColor3 = Color3.new(1, 1, 1)
upButton.Visible = false
upButton.Parent = mobileControls

local downButton = Instance.new("TextButton")
downButton.Name = "DownButton"
downButton.Size = UDim2.new(0.15, 0, 0.1, 0)
downButton.Position = UDim2.new(0.8, 0, 0.95, 0)
downButton.AnchorPoint = Vector2.new(0.5, 0.5)
downButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
downButton.Text = "▼"
downButton.TextScaled = true
downButton.TextColor3 = Color3.new(1, 1, 1)
downButton.Visible = false
downButton.Parent = mobileControls


local function roundCorners(guiObject, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(cornerRadius, 0)
    corner.Parent = guiObject
end


roundCorners(joystickFrame, 0.2)
roundCorners(joystickInner, 0.5)
roundCorners(toggleButton, 0.2)
roundCorners(upButton, 0.2)
roundCorners(downButton, 0.2)
roundCorners(pcControls, 0.2)


local Joystick = {}
Joystick.__index = Joystick

function Joystick.new(container, inner, options)
    local self = setmetatable({}, Joystick)
    
    -- Configuration
    self.options = {
        deadzone = options.deadzone or 0.1,
        maxDistance = options.maxDistance or 100,
        moveRange = options.moveRange or 0.3, -- As fraction of container size
        tweenInfo = options.tweenInfo or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    }
    
    -- References
    self.container = container
    self.inner = inner
    self.connections = {}
    
    -- State
    self.isActive = false
    self.currentPosition = Vector2.new(0, 0)
    self.startPosition = Vector2.new(0, 0)
    self.currentInput = nil
    self.activeTween = nil
    
    -- Initialize
    self:setup()
    
    return self
end

function Joystick:setup()
    -- Store container properties
    local containerAbsPos = self.container.AbsolutePosition
    local containerSize = self.container.AbsoluteSize
    
    self.containerProps = {
        position = Vector2.new(containerAbsPos.X, containerAbsPos.Y),
        size = Vector2.new(containerSize.X, containerSize.Y),
        center = Vector2.new(containerAbsPos.X + containerSize.X/2, containerAbsPos.Y + containerSize.Y/2)
    }
    
    -- Connect events
    self:connectEvents()
end

function Joystick:connectEvents()
    -- Clean up any existing connections
    self:disconnectEvents()
    
    -- Connect new events
    table.insert(self.connections, self.container.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch or self.isActive then return end
        self:onInputBegan(input)
    end))
    
    table.insert(self.connections, game:GetService("UserInputService").InputChanged:Connect(function(input)
        if not self.isActive or input ~= self.currentInput then return end
        self:onInputChanged(input)
    end))
    
    table.insert(self.connections, game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input == self.currentInput then
            self:onInputEnded()
        end
    end))
end

function Joystick:disconnectEvents()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
end

function Joystick:onInputBegan(input)
    self.isActive = true
    self.currentInput = input
    self.startPosition = Vector2.new(input.Position.X, input.Position.Y)
    
    -- Visual feedback
    self.inner.ImageTransparency = 0.7
end

function Joystick:onInputChanged(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    
    local currentPos = Vector2.new(input.Position.X, input.Position.Y)
    local delta = currentPos - self.startPosition
    local distance = math.min(delta.Magnitude, self.options.maxDistance)
    
    if distance > 0 then
        -- Update position
        local direction = delta.Unit
        self.currentPosition = direction * (distance / self.options.maxDistance)
        
        -- Update visual
        local maxOffset = self.container.AbsoluteSize.X * self.options.moveRange
        local offset = direction * math.min(distance, maxOffset)
        self:setInnerPosition(offset)
    end
end

function Joystick:onInputEnded()
    self.isActive = false
    self.currentPosition = Vector2.new(0, 0)
    self.currentInput = nil
    
    -- Reset visual with tween
    self:resetInnerPosition()
    
    -- Visual feedback
    self.inner.ImageTransparency = 0.9
end

function Joystick:setInnerPosition(offset)
    if self.activeTween then
        self.activeTween:Cancel()
        self.activeTween = nil
    end
    
    self.inner.Position = UDim2.new(
        0.5, offset.X,
        0.5, offset.Y
    )
end

function Joystick:resetInnerPosition()
    if self.activeTween then
        self.activeTween:Cancel()
    end
    
    self.activeTween = TweenService:Create(
        self.inner,
        self.options.tweenInfo,
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    self.activeTween:Play()
    
    self.activeTween.Completed:Connect(function()
        self.activeTween = nil
    end)
end

function Joystick:getPosition()
    if not self.isActive then return Vector2.new(0, 0) end
    return self.currentPosition
end

function Joystick:destroy()
    self:disconnectEvents()
    
    if self.activeTween then
        self.activeTween:Cancel()
        self.activeTween = nil
    end
    
    setmetatable(self, nil)
end

local joystick = nil

if IS_MOBILE then
    joystickInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    joystickInner.BackgroundTransparency = 0.9
    joystickInner.BorderSizePixel = 0
    
    joystickFrame.BackgroundTransparency = 0.9
    joystickFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    joystick = Joystick.new(joystickFrame, joystickInner, {
        deadzone = 0.1,
        maxDistance = 100,
        moveRange = 0.4
    })
    
    local function setupButton(button)
        button:SetAttribute("IsPressed", false)
        
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                button:SetAttribute("IsPressed", true)
                button.BackgroundTransparency = 0.7
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                button:SetAttribute("IsPressed", false)
                button.BackgroundTransparency = 0.9
            end
        end)
        
        button.MouseLeave:Connect(function()
            if button:GetAttribute("IsPressed") then
                button:SetAttribute("IsPressed", false)
                button.BackgroundTransparency = 0.9
            end
        end)
    end
    
    setupButton(upButton)
    setupButton(downButton)
    
    upButton.BackgroundTransparency = 0.9
    downButton.BackgroundTransparency = 0.9
end


local CoreGui = game:GetService("CoreGui")
gui.Parent = CoreGui

local flying = false
local bodyGyro, bodyVelocity
local flyConnection

-- Notification function
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- Fly logic
local function startFlying(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 15000
    bodyGyro.D = 500
    bodyGyro.MaxTorque = Vector3.new(1/0, 1/0, 1/0)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying then return end

        local cam = workspace.CurrentCamera
        local moveDir = Vector3.zero

        -- Keyboard controls (for testing)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir += cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir -= cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir += cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir -= cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(UP_KEY) then
            moveDir += Vector3.yAxis
        end
        if UserInputService:IsKeyDown(DOWN_KEY) then
            moveDir -= Vector3.yAxis
        end

        -- Mobile joystick controls
        if IS_MOBILE and joystick then
            local joystickPos = joystick:getPosition()
            if joystickPos.Magnitude > 0.1 then
                moveDir += cam.CFrame.RightVector * joystickPos.X
                moveDir += cam.CFrame.LookVector * -joystickPos.Y
            end
        end

        -- Mobile up/down buttons
        if IS_MOBILE then
            if upButton:GetAttribute("IsPressed") then
                moveDir += Vector3.yAxis
            end
            if downButton:GetAttribute("IsPressed") then
                moveDir -= Vector3.yAxis
            end
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * FLY_SPEED
        end

        bodyVelocity.Velocity = moveDir
        bodyGyro.CFrame = cam.CFrame
    end)
end

-- Toggle fly
local function toggleFly()
    flying = not flying
    if flying then
        if Player.Character then
            startFlying(Player.Character)
            if IS_MOBILE then
                toggleButton.Text = "✈️ FLY (ON)"
                toggleButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
                upButton.Visible = true
                downButton.Visible = true
                notify("Fly Hack", "Flying enabled. Use joystick to move!")
            else
                notify("Fly Hack", "Flying enabled. Use WASD + SPACE/SHIFT to move!")
            end
        end
    else
        if flyConnection then flyConnection:Disconnect() end
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
        bodyGyro = nil
        bodyVelocity = nil
if IS_MOBILE then
            toggleButton.Text = "✈️ FLY (OFF)"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            upButton.Visible = false
            downButton.Visible = false
        end
        notify("Fly Hack", "Flying disabled.")
    end
end

if IS_MOBILE then
    toggleButton.MouseButton1Click:Connect(toggleFly)
    toggleButton.TouchTap:Connect(toggleFly)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        toggleFly()
    end
end)


Player.CharacterAdded:Connect(function(character)
    if flyConnection then flyConnection:Disconnect() end
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    bodyGyro = nil
    bodyVelocity = nil
    flying = false
    
    
    toggleButton.Text = "✈️ FLY (OFF)"
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    upButton.Visible = false
    downButton.Visible = false
end)


return function()
    flying = false
    if flyConnection then flyConnection:Disconnect() end
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
    bodyGyro = nil
    bodyVelocity = nil
end
