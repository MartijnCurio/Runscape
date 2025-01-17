-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local shopFrame = mainUI:WaitForChild("ShopFrame")
local upgradesList = shopFrame:WaitForChild("UpgradesList")

local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local PlayerModule = require(sharedFolder:WaitForChild("PlayerModule"))(localPlayer)
local upgradesModule = require(ReplicatedStorage:WaitForChild("Upgrades"))

local runHasStarted = false
local stopBackgroundMusicLoop = false
local doubleJumpActive = true

local isRunning = false
local runningSpeedTransitionTime = 5

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

    isRunning = true

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
    localHumanoid:GetAttributeChangedSignal("BaseWalkSpeed"):Connect(function()
        if not isRunning then return end
        localHumanoid.WalkSpeed = localHumanoid:GetAttribute("BaseWalkSpeed")
    end)
    localHumanoid:GetAttributeChangedSignal("BaseJumpPower"):Connect(function()
        if not isRunning then return end
        localHumanoid.JumpPower = localHumanoid:GetAttribute("BaseJumpPower")
    end)

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
        if gameProcessed then return end

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

function HandleShopToggle(state: boolean)
    -- Toggle shop and running state
    shopFrame.Visible = state
    isRunning = not state

    if not runHasStarted then return end

    if state then
        localHumanoid.WalkSpeed = 0
    else
        -- Shop has been closed
        TweenService:Create(localHumanoid, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            WalkSpeed = localHumanoid:GetAttribute("BaseWalkSpeed")
        }):Play()
    end

    TweenService:Create(localCamera, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        FieldOfView = state and introCameraFOV or baseCameraFOV
    }):Play()
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

for key, data in next, upgradesModule do
    local template = upgradesList.Template:Clone()
    local inner = template:WaitForChild("Inner")

    template.Visible = true
    inner.Name = key
    inner.Title.Text = data.Title
    inner.Desc.Text = data.Desc
    inner.Cost.Text = data.Cost
    inner.Parent = upgradesList

    inner.BuyButton.Activated:Connect(function()
        ReplicatedStorage.BuyUpgrade:InvokeServer(key)
    end)
end

-- Set up humanoid and camera
localHumanoid.WalkSpeed = 0
localCamera.CameraType = Enum.CameraType.Scriptable
localCamera.FieldOfView = introCameraFOV

-- Set up controls and camera update loop
Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    if not PlayerModule:IsAlive() then return end

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
        doubleJumpActive = true
        jumpTrack:Stop()
    end
end)

shopFrame.Close.Activated:Connect(function()
    HandleShopToggle(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space
    and localHumanoid.FloorMaterial == Enum.Material.Air
    and doubleJumpActive
    and localHumanoid:GetAttribute("DoubleJump") then
        doubleJumpActive = false
        localHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local isFirstJumpPad: boolean = true
ReplicatedStorage:WaitForChild("OnChunkLoaded").OnClientEvent:Connect(function(rawName: string, chunk: Model)
    warn(rawName)
    if isFirstJumpPad then
        local chunks = workspace.CurrentChunks:GetChildren()
        table.sort(chunks, function(a, b)
            return tonumber(a.Name) < tonumber(b.Name)
        end)
        for _, c in next, chunks do
            if c:GetAttribute("RawName") == "JumpPad" then
                for _, o in next, c:WaitForChild("Obstacles"):GetChildren() do
                    if o:IsA("Model") and o.Name == "JumpPad" then
                        isFirstJumpPad = false
                        o.Gui.Enabled = true
                        break
                    end
                end
                if not isFirstJumpPad then break end
            end
        end
    end
end)

ReplicatedStorage:WaitForChild("ToggleShop").OnClientEvent:Connect(HandleShopToggle)