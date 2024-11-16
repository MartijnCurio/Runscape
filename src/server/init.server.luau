-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Variables
local ChunksFolder = workspace:WaitForChild("Chunks")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))

-- Main
if workspace:FindFirstChild("Baseplate") then
    -- Destroy Baseplate
    workspace.Baseplate:Destroy()
end
if workspace:FindFirstChild("SpawnLocation") then
    -- Destroy SpawnLocation
    workspace.SpawnLocation:Destroy()
end

ChunksFolder.Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        -- Initialize Path
        local Path = require(script:WaitForChild("PathCreator"))(player)
        Path:Init()

        -- Handle path destroy
        player.CharacterRemoving:Connect(function()
            Path:Destroy()
        end)

        -- Ragdoll on Death
        local humanoid = character:WaitForChild("Humanoid")
        
        ReplicatedStorage.KillPlayer.Event:Connect(function(plr)
            if plr ~= player or not plr.Character then return end

            -- Ragdoll
            local motors = Ragdoll.CreateJoints(plr.Character)
            Ragdoll.SetMotorsEnabled(motors, true)
            Ragdoll.Ragdoll(plr.Character)

            -- Kill
            humanoid.Health = 0
        end)
    end)
end)

ReplicatedStorage.Respawn.OnServerInvoke = function(player: Player)
    player:LoadCharacter()
end