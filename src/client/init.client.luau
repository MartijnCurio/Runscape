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

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local runHasStarted = false
local doJump = false

local runningSpeed = 40
local runningSpeedTransitionTime = 7
local jumpPower = 50

local introCameraFOV = 20
local baseCameraFOV = 50
local baseCameraOffsetCFrame = CFrame.new(40, 6, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-7.5), 0, 0)

-- Functions
function StartRun(args)
    if runHasStarted then
        return
    end
    assert(remotesFolder.StartRun:InvokeServer(), "Failed to start run on server")
    
    -- Start run
    TweenService:Create(homeScreenGui.Background, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(0, 0, -1, 0)
    }):Play()

    task.wait(3)

    homeScreenGui.Enabled = false
    runHasStarted = true
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
end

function IsAlive()
    return localCharacter ~= nil and localHumanoid.Health > 0
end

-- Main
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

homeScreenGui.Background.Buttons.PlayButton.Activated:Once(StartRun)
homeScreenGui.Enabled = true

if UserInputService.TouchEnabled then
	UserInputService.ModalEnabled = true
	
    UserInputService.TouchStarted:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent == false then
            doJump = true
        end
    end)

	UserInputService.TouchEnded:Connect(function()
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

localHumanoid.WalkSpeed = 0
localCamera.CameraType = Enum.CameraType.Scriptable
localCamera.FieldOfView = introCameraFOV

RunService.RenderStepped:Connect(function()
    if not IsAlive() then return end

    -- Movement
    do
        if doJump then
            -- Jump
            localHumanoid.Jump = true
        end
    
        -- Move forward
        localHumanoid:Move(Vector3.new(0, 0, -1), false)
    end

    -- Camera
    do
        localCamera.CFrame = localRootPart:WaitForChild("CamPos").WorldCFrame
    end
end)