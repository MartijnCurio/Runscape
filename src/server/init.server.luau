-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerStatsDataStore = DataStoreService:GetDataStore("PlayerStats")

local DefaultPlayerStats = {
    Coins = 0,
    Deaths = 0,
    Distance = 0,
    Highscore = 0
}
local PlayerData = {}

-- Variables
local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))
local UpgradesModule = require(ReplicatedStorage:WaitForChild("Upgrades"))

-- Functions
function Init(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Set base attributes
    humanoid:SetAttribute("BaseWalkSpeed", 40)
    humanoid:SetAttribute("BaseJumpPower", 65)
    humanoid:SetAttribute("DoubleJump", false)
    
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

function GetPlayerData(userId: number): any
    if PlayerData[userId] then
        return PlayerData[userId]
    end
    local _, data = pcall(function()
        return PlayerStatsDataStore:GetAsync(userId)
    end)
    return data or DefaultPlayerStats
end

function CreateLeaderstats(player: Player, playerData: any): Folder
    -- Create folder
    local folder = Instance.new("Folder")
    folder.Name = "leaderstats"
    folder.Parent = player
    
    -- Create stats
    for name, value in next, playerData do
        local stat = Instance.new("IntValue")
        stat.Name = name
        stat.Value = value
        stat.Parent = folder

        -- Detect value changes
        stat:GetPropertyChangedSignal("Value"):Connect(function()
            PlayerData[player.UserId][name] = stat.Value
        end)
    end

    return folder
end

-- Main
workspace:WaitForChild("Chunks").Parent = ReplicatedStorage
workspace:WaitForChild("Obstacles").Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(player: Player)
    -- Get player data
    local playerData = GetPlayerData(player.UserId)
    PlayerData[player.UserId] = playerData

    -- Create leaderstats
    CreateLeaderstats(player, playerData)

    -- Wait for player to load character
    player.CharacterAdded:Connect(function()
        -- Reset coins
        player.leaderstats.Coins.Value = 0

        Init(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    -- Get player data
    local playerData = GetPlayerData(player.UserId)

    -- Save player data
    local success, err = pcall(function()
        PlayerStatsDataStore:SetAsync(player.UserId, playerData)
    end)
    if not success then
        warn("Failed to save data for player " .. player.UserId .. ": " .. err)
    end
end)

ReplicatedStorage.Respawn.OnServerInvoke = function(player: Player)
    player:LoadCharacter()
end

ReplicatedStorage.GetPlayerData.OnInvoke = function(userId: number)
    return GetPlayerData(userId)
end

ReplicatedStorage.SetPlayerData.OnInvoke = function(userId: number, data: any)
    PlayerData[userId] = data
end

ReplicatedStorage.BuyUpgrade.OnServerInvoke = function(player: Player, upgradeKey: string)
    -- Get selected upgrade
    local selectedUpgrade = UpgradesModule[upgradeKey]
    if not selectedUpgrade then return end

    -- Get player coins
    local leaderstats = player:WaitForChild("leaderstats")
    local coins = leaderstats:WaitForChild("Coins")

    -- Check if player has enough coins
    if coins.Value < selectedUpgrade.Cost then return end

    -- Check if upgrade can stack
    if not selectedUpgrade.CanStack and player.Backpack:FindFirstChild(upgradeKey) then return end

    -- Apply upgrade effect and check if successful
    if selectedUpgrade.Callback(player) then
        -- Subtract coins
        coins.Value -= selectedUpgrade.Cost
    end
end