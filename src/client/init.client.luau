-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

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

local baseCameraFOV = 50
local baseCameraOffsetCFrame =  CFrame.new(35, 6, -16) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(-7.5), 0, 0)
local cameraShakeOffsetValue = Instance.new("NumberValue")
local cameraFOVOffsetValue = Instance.new("NumberValue")

-- Functions
function StartRun(args)
    if runHasStarted then
        return
    end

    -- Start run
    assert(remotesFolder.StartRun:InvokeServer(), "Failed to start run")
    
    homeScreenGui.Enabled = false
    runHasStarted = true
    localHumanoid.WalkSpeed = runningSpeed
end

function IsAlive()
    return localCharacter ~= nil and localHumanoid.Health > 0
end

-- Main
homeScreenGui.StartButton.Activated:Connect(StartRun)
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
localCamera.FieldOfView = baseCameraFOV

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
        localCamera.CFrame = CFrame.new(localRootPart.Position) * baseCameraOffsetCFrame * CFrame.Angles(0, 0, math.rad(cameraShakeOffsetValue.Value))
        localCamera.FieldOfView = baseCameraFOV + cameraFOVOffsetValue.Value
    end
end)

-- Camera shake and fov offset
task.spawn(function()
    cameraShakeOffsetValue.Value = localCamera.CFrame
    cameraFOVOffsetValue.Value = localCamera.FieldOfView

    while IsAlive() do
        local duration = math.random(200, 700) / 1000
        
        -- Shake camera
        TweenService:Create(cameraShakeOffsetValue, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
            Value = math.random(-500, 500) / 1000
        }):Play()

        -- Change fov
        TweenService:Create(cameraFOVOffsetValue, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
            Value = math.random(-500, 500) / 1000
        }):Play()

        task.wait(duration)
    end
end)