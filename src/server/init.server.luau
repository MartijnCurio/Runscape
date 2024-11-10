-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Variables
local ChunksFolder = workspace:WaitForChild("Chunks")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- Functions
function Init(player: Player)
    -- Destroy Baseplate
    if workspace:FindFirstChild("Baseplate") then
        workspace.Baseplate:Destroy()
    end
    -- Destroy SpawnLocation
    if workspace:FindFirstChild("SpawnLocation") then
        workspace.SpawnLocation:Destroy()
    end

    -- Initialize Path
    local Path = require(script:WaitForChild("PathCreator"))(player)
    Path:Init()
end

-- Main
ChunksFolder.Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAppearanceLoaded:Wait()
    
    -- All players loaded (placeholder)

    Init(player)
end)

remotesFolder.StartRun.OnServerInvoke = function()
    return true -- Placeholder
end