-- Services
local Players = game:GetService("Players")

-- Main
return function(player: Player): PlayerModule
    local PlayerModule = {
        Player = player
    }

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