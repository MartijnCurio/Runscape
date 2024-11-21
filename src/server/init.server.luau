-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Variables
local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))

-- Functions
function Init(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Set base attributes
    humanoid:SetAttribute("BaseWalkSpeed", 40)
    humanoid:SetAttribute("BaseJumpPower", 65)
    
    -- Initialize Path
    local Path = require(script:WaitForChild("PathCreator"))(player)
    Path:Init()

    -- Handle path destroy
    player.CharacterRemoving:Connect(function()
        Path:Destroy()
    end)

    -- Ragdoll on Death
    ReplicatedStorage.KillPlayer.Event:Connect(function(plr: Player)
        if plr ~= player then return end

        -- Ragdoll
        local motors = Ragdoll.CreateJoints(character)
        Ragdoll.SetMotorsEnabled(motors, true)
        Ragdoll.Ragdoll(character)

        -- Kill
        humanoid.Health = 0
    end)
end

-- Main
workspace:WaitForChild("Chunks").Parent = ReplicatedStorage
workspace:WaitForChild("Obstacles").Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Wait()
    Init(player)
end)

ReplicatedStorage.Respawn.OnServerInvoke = function(player: Player)
    player:LoadCharacter()
end