-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))

-- Functions
local function getPlayerFromHitPart(hit: BasePart): Player?
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
    end,
    IceBreak = function(hitbox: BasePart)
        local iceBreak = hitbox.Parent
        local ice = iceBreak.Ice
        local water = iceBreak.Water

        local broken = false

        hitbox.Touched:Connect(function(hit: BasePart)
            if broken then return end -- Ice is already broken

            local plr = getPlayerFromHitPart(hit)
            if not plr then return end
            
            -- Break ice
            broken = true
            hitbox.Cracking:Play()

            task.wait(0.25)

            ice:Destroy()

            -- Water touch event
            water.Touched:Connect(function(waterHit: BasePart)
                local waterPlr = getPlayerFromHitPart(waterHit)
                if waterPlr and waterPlr == plr then
                    ReplicatedStorage.KillPlayer:Fire(plr)
                    hitbox.Splash:Play()
                end
            end)
        end)
    end,
}