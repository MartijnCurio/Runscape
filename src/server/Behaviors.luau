-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Main
return {
    TouchKill = function(hitbox: BasePart)
        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            for _, plr in next, Players:GetPlayers() do
                if plr.Character and hit:IsDescendantOf(plr.Character) then
                    local humanoid = plr.Character:FindFirstChild("Humanoid")

                    if humanoid and humanoid.Health > 0 then
                        -- Kill player
                        ReplicatedStorage.KillPlayer:Fire(plr)
                    end

                    break
                end
            end
        end)
    end,
    JumpPad = function(hitbox: BasePart)
        local debounce = false

        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            for _, plr in next, Players:GetPlayers() do
                if plr.Character and hit:IsDescendantOf(plr.Character) and not debounce then
                    debounce = true

                    local humanoid = plr.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local oldJumpPower = humanoid.JumpPower

                        humanoid.JumpPower = 100

                        task.delay(1, function()
                            humanoid.JumpPower = oldJumpPower
                            debounce = false
                        end)
                    end

                    break
                end
            end
        end)
    end
}