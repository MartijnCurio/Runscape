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
local backgroundMusicFolder = workspace:WaitForChild("BackgroundMusic")

local localPlayerGui = localPlayer:WaitForChild("PlayerGui")
local homeScreenGui = localPlayerGui:WaitForChild("HomeScreen")
local mainUI = localPlayerGui:WaitForChild("MainUI")

local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local PlayerModule = require(sharedFolder:WaitForChild("PlayerModule"))(localPlayer)

local runHasStarted = false
local enableControls = false
local doJump = false
local stopBackgroundMusicLoop = false

local runningSpeedTransitionTime = 6

local introCameraFOV = 20
local baseCameraFOV = 50
local baseCameraOffsetCFrame = CFrame.new(40, 6, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-7.5), 0, 0)

local jumpAnimation = assetsFolder:WaitForChild("JumpFlip"):Clone()
local jumpSound = assetsFolder:WaitForChild("JumpSound"):Clone()
local jumpTrack = localHumanoid:LoadAnimation(jumpAnimation)

local Connections = {}
local Tweens = {}

-- Functions
function StartRun(args)
    if runHasStarted then
        return
    end
    
    runHasStarted = true
    
    -- Track leaderstats
    local leaderstats = localPlayer:FindFirstChild("leaderstats")

    leaderstats:WaitForChild("Distance"):GetPropertyChangedSignal("Value"):Connect(function()
        mainUI.DistanceLabel.Text = math.floor(leaderstats.Distance.Value).. "m"
    end)

    -- Start run
    TweenService:Create(homeScreenGui.Background, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(0, 0, -1, 0)
    }):Play()

    task.wait(3)

    homeScreenGui.Enabled = false
    localHumanoid.WalkSpeed = 2
    localHumanoid.UseJumpPower = true
    localHumanoid.JumpPower = localHumanoid:GetAttribute("BaseJumpPower")

    -- Start background music loop
    task.spawn(StartBackgroundMusicLoop, backgroundMusicFolder.BackgroundStart)

    -- Intro tweening
    local tweenInfo = TweenInfo.new(runningSpeedTransitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

    TweenService:Create(localHumanoid, tweenInfo, {
        WalkSpeed = localHumanoid:GetAttribute("BaseWalkSpeed")
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
    local leaderstats = localPlayer:FindFirstChild("leaderstats")
    local statsHolder = mainUI.Death:WaitForChild("Statistics")

    statsHolder.Visible = false -- TESTING : TO DO IMPLEMENTATION

    -- Display stats
    for _, stat in next, leaderstats:GetChildren() do
        local template = statsHolder.Template:Clone()
        template.Visible = true
        template.Name = stat.Name
        template.Stat.Text = stat.Name
        template.Value.Text = math.floor(stat.Value)
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

            -- Disconnect all active connections (again)
            for _, connection in next, Connections do
                connection:Disconnect()
            end
            -- Cancel all tweens
            for _, tween in next, Tweens do
                tween:Cancel()
            end

            -- Request a respawn from the server
            RequestRespawn()
        end
    end)
end

function StartBackgroundMusicLoop(sound: Sound?)
    local selectedSound = sound
    if not selectedSound then
        selectedSound = backgroundMusicFolder:GetChildren()[math.random(1, #backgroundMusicFolder:GetChildren())]
    end

    local tweenInfo = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    selectedSound.Volume = 0
    selectedSound:Play()
    TweenService:Create(selectedSound, tweenInfo, { Volume = 0.375 }):Play()

    repeat RunService.RenderStepped:Wait() until stopBackgroundMusicLoop or selectedSound.TimePosition >= (selectedSound.TimeLength - tweenInfo.Time)

    TweenService:Create(selectedSound, tweenInfo, { Volume = 0 }):Play()

    if stopBackgroundMusicLoop then
        return
    end

    task.wait(tweenInfo.Time)

    StartBackgroundMusicLoop()
end

function RequestRespawn()
    warn("Requesting respawn")
    ReplicatedStorage.Respawn:InvokeServer()
end

-- Main
task.delay(0.5, function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCore("ResetButtonCallback", false)
end)

jumpSound.Parent = script

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

    -- Fade out background music
    stopBackgroundMusicLoop = true

    -- Tween camera to focus player
    Tweens.CameraDeathPan = TweenService:Create(localCamera, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        CFrame = CFrame.lookAt((localRootPart.CFrame * baseCameraOffsetCFrame).Position, localRootPart.Position),
        FieldOfView = introCameraFOV
    }):Play()

    -- Game over
    GameOver()
end)

localHumanoid.StateChanged:Connect(function(oldState, newState)
    if newState == Enum.HumanoidStateType.Jumping then
        jumpSound:Play()
        jumpTrack:Play()
        jumpTrack:AdjustSpeed(1 / 16 * localHumanoid:GetAttribute("BaseWalkSpeed") * 0.75)

    elseif newState == Enum.HumanoidStateType.Landed then
        jumpTrack:Stop()
    end
end)