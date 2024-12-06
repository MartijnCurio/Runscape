-- Services
local Players = game:GetService("Players")

-- Main
return function(player: Player): PlayerModule
    local PlayerModule = {
        Player = player
    }

    function PlayerModule:InitializeStats()
        assert(self.Character, "Character not found")

        -- Create stats folder
        local statsFolder = Instance.new("Folder")
        statsFolder.Name = "Stats"

        -- Distance
        local distanceStat = Instance.new("NumberValue")
        distanceStat.Name = "Distance"
        distanceStat.Value = 0
        distanceStat.Parent = statsFolder
        
        -- Coins collected
        local coinsStat = Instance.new("IntValue")
        coinsStat.Name = "Coins"
        coinsStat.Value = 0
        coinsStat.Parent = statsFolder

        -- Add stats folder to character
        statsFolder.Parent = self.Character
    end

    function PlayerModule:OnStatChanged(statName: string, callback: (number) -> ())
        assert(self.Character, "Character not found")

        local statsFolder = self.Character:WaitForChild("Stats")
        assert(statsFolder, "Stats folder not found")

        local stat = statsFolder:WaitForChild(statName)
        assert(stat, "Stat not found")

        stat:GetPropertyChangedSignal("Value"):Connect(function()
            callback(stat.Value)
        end)
    end

    function PlayerModule:IsAlive(): boolean
        if not self.Character or not self.Humanoid or self.Humanoid.Health <= 0 then
            return false
        end
        return true
    end

    player.CharacterAdded:Connect(function(character)
        PlayerModule.Character = character
        PlayerModule.Humanoid = character:WaitForChild("Humanoid")
    end)

    if player.Character then
        PlayerModule.Character = player.Character
        PlayerModule.Humanoid = player.Character:WaitForChild("Humanoid")
    end

    return PlayerModule
end