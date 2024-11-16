-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))

-- Functions
local function getPlayerFromHitPart(hit: BasePart)
    for _, plr in next, Players:GetPlayers() do
        if plr.Character and hit:IsDescendantOf(plr.Character) then
            return plr
        end
    end
end

-- Main
return {
    TouchKill = function(hitbox: BasePart)
        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            local plr = getPlayerFromHitPart(hit)

            if plr and plr.Character then
                local humanoid = plr.Character:FindFirstChild("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    -- Kill player
                    ReplicatedStorage.KillPlayer:Fire(plr)
                end
            end
        end)
    end,
    JumpPad = function(hitbox: BasePart)
        local debounce = false

        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            local plr = getPlayerFromHitPart(hit)

            if plr and plr.Character and not debounce then
                debounce = true

                local humanoid = plr.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid.JumpPower = 100

                    task.delay(1, function()
                        humanoid.JumpPower = humanoid:GetAttribute("BaseJumpPower")
                        debounce = false
                    end)
                end
            end
        end)
    end,
    Zombie = function(hitbox: BasePart)
        local zombie = hitbox.Parent
        local zombieHumanoid = zombie:FindFirstChild("Humanoid")

        if zombieHumanoid.Health <= 0 then return end

        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            local plr = getPlayerFromHitPart(hit)

            if plr and plr.Character then
                local humanoid = plr.Character:FindFirstChild("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    -- Kill player
                    ReplicatedStorage.KillPlayer:Fire(plr)
                end
            end
        end)
    end,
    TallGrass = function(hitbox: BasePart)
        local debounce = false
        
        hitbox.Touched:Connect(function(hit: BasePart)
            -- Get player from hit part
            local plr = getPlayerFromHitPart(hit)

            if plr and plr.Character and not debounce then
                debounce = true

                local humanoid = plr.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    -- Play sound inside hitbox
                    hitbox.Sound:Play()
                    humanoid.WalkSpeed = humanoid:GetAttribute("BaseWalkSpeed") * 0.5

                    task.delay(1, function()
                        humanoid.WalkSpeed = humanoid:GetAttribute("BaseWalkSpeed")
                        debounce = false
                    end)
                end
            end
        end)
    end
}