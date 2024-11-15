-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Variables
local localPlayer = Players.LocalPlayer
local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localHumanoid = localCharacter:WaitForChild("Humanoid")
local localRootPart = localCharacter:WaitForChild("HumanoidRootPart")
local localCamera = workspace.CurrentCamera

local localPlayerGui = localPlayer:WaitForChild("PlayerGui")
local homeScreenGui = localPlayerGui:WaitForChild("HomeScreen")
local mainUI = localPlayerGui:WaitForChild("MainUI")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local PlayerModule = require(sharedFolder:WaitForChild("PlayerModule"))(localPlayer)

local runHasStarted = false
local enableControls = false
local doJump = false

local runningSpeed = 40
local runningSpeedTransitionTime = 7
local jumpPower = 60

local introCameraFOV = 120 -- 20
local baseCameraFOV = 120 -- 50
local baseCameraOffsetCFrame = CFrame.new(40, 6, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-7.5), 0, 0)

local Connections = {}

-- Functions
function StartRun(args)
    if runHasStarted then
        return
    end
    
    runHasStarted = true
    
    -- Start run
    PlayerModule:OnStatChanged("Distance", function(value)
        if not PlayerModule:IsAlive() then return end
        mainUI.DistanceLabel.Text = math.floor(value) .. "m"
    end)

    TweenService:Create(homeScreenGui.Background, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(0, 0, -1, 0)
    }):Play()

    task.wait(3)

    homeScreenGui.Enabled = false
    localHumanoid.WalkSpeed = 2
    localHumanoid.UseJumpPower = true
    localHumanoid.JumpPower = jumpPower

    -- Intro tweening
    local tweenInfo = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

    TweenService:Create(localHumanoid, tweenInfo, {
        WalkSpeed = runningSpeed
    }):Play()

    TweenService:Create(localRootPart:WaitForChild("CamPos"), tweenInfo, {
        CFrame = baseCameraOffsetCFrame * CFrame.new(20, 0, 0)
    }):Play()

    TweenService:Create(localCamera, tweenInfo, {
        FieldOfView = baseCameraFOV
    }):Play()

    task.wait(6)

    -- Enable controls
    enableControls = true

    TweenService:Create(mainUI.DistanceLabel, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new()
    }):Play()
end

function GameOver()
    local stats = PlayerModule:GetStats()

    local statsHolder = mainUI.Death:WaitForChild("Statistics")

    -- Display stats
    for name, value in next, stats do
        local template = statsHolder.Template:Clone()
        template.Visible = true
        template.Name = name
        template.Stat.Text = name
        template.Value.Text = math.floor(value)
        template.Parent = statsHolder
    end

    -- Display death screen
    mainUI.DistanceLabel.Visible = false
    mainUI.Death.Visible = true

    -- Press any key to respawn
    local inputBegan; inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then return end

        -- Check if keyboad key or gamepad button was pressed
        if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
            inputBegan:Disconnect()
            RequestRespawn()
        end
    end)
end

function RequestRespawn()
    warn("Requesting respawn")
    ReplicatedStorage.Respawn:InvokeServer()
end

-- Main
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCore("ResetButtonCallback", false)

homeScreenGui.Enabled = true
mainUI.Death.Visible = false
homeScreenGui:WaitForChild("Background").Buttons.PlayButton.Activated:Once(StartRun)

-- Connect player controls
if UserInputService.TouchEnabled then
    UserInputService.ModalEnabled = true
    
    Connections.TouchStarted = UserInputService.TouchStarted:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent == false then
            doJump = true
        end
    end)

    Connections.TouchEnded = UserInputService.TouchEnded:Connect(function()
        doJump = false
    end)
else
    ContextActionService:BindAction(
        "Jump",
        function(action, userInputState, inputObject)
            doJump = (userInputState == Enum.UserInputState.Begin)
        end,
        false,
        Enum.KeyCode.Space, Enum.KeyCode.ButtonA
    )
end

-- Set up humanoid and camera
localHumanoid.WalkSpeed = 0
localCamera.CameraType = Enum.CameraType.Scriptable
localCamera.FieldOfView = introCameraFOV

-- Set up controls and camera update loop
Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    if not PlayerModule:IsAlive() then return end

    -- Controls
    if enableControls and doJump then
        localHumanoid.Jump = true
    end

    -- Move forward
    localHumanoid:Move(Vector3.new(0, 0, -1), false)

    -- Camera
    localCamera.CFrame = localRootPart:WaitForChild("CamPos").WorldCFrame
end)

-- Set up death handler
Connections.Died = localHumanoid.Died:Connect(function()
    for _, connection in next, Connections do
        connection:Disconnect()
    end

    -- Game over
    GameOver()
end)