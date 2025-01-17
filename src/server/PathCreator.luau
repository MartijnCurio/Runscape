-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
local currentChunksFolder = workspace:WaitForChild("CurrentChunks")
local chunksFolder = ReplicatedStorage:WaitForChild("Chunks")
local obstaclesFolder = ReplicatedStorage:WaitForChild("Obstacles")
local propsFolder = ReplicatedStorage:WaitForChild("Props")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")

local Biomes = require(script.Parent:WaitForChild("Biomes"))
local Behaviors = require(script.Parent:WaitForChild("Behaviors"))

local studsToMetersFactor = 0.28

-- Main
return function(player: Player)
    local Path = {
        Const = {
            ChunksAhead = 3,
            ChunksBehind = 3,
            BiomeChangeChance = 10
        },
        Biome = Biomes.Biomes[Biomes.KeyNames[math.random(1, #Biomes.KeyNames)]],
        Chunks = {},
        ChunkID = 0,
        BiomeChunkCount = 0
    }

    local PlayerModule = require(sharedFolder:WaitForChild("PlayerModule"))(player)

    function Path:GenerateChunk(selectedChunk: Model?): Model
        local chunk;

        if selectedChunk == nil then
            -- Check change biome
            self:CheckChangeBiome()
            self.BiomeChunkCount += 1

            local biomeFolder = chunksFolder:FindFirstChild(self.Biome.Name)
            assert(biomeFolder ~= nil, "Biome folder not found")
            
            -- Populate chunks table
            local chunks = {}
            for _, chunk in next, biomeFolder:GetChildren() do
                if not table.find(self.Biome.IgnoreList, chunk.Name) then
                    table.insert(chunks, chunk)
                end
            end
            assert(#chunks > 0, "No chunks found")

            -- Get random chunk
            chunk = chunks[math.random(1, #chunks)]:Clone()
        else
            chunk = selectedChunk:Clone()
        end
        assert(chunk ~= nil, "Chunk not found")

        -- Hide base elements
        for _, basepart in next, chunk:GetChildren() do
            if basepart:IsA("BasePart") and basepart.Name:find("Base") then
                basepart.Transparency = 1
            end
        end

        -- Position chunk
        local currentChunks = currentChunksFolder:GetChildren()
        if #currentChunks > 0 then
            local lastChunk = currentChunks[#currentChunks]
            local baseEnd = lastChunk:WaitForChild("BaseEnd")
            chunk:PivotTo(baseEnd.CFrame)
        else
            chunk:PivotTo(CFrame.new())
        end

        -- Dynamically populate coins
        local chunkCoinsFolder = chunk:FindFirstChild("Coins")
        if chunkCoinsFolder then
            for _, coinSpawn in next, chunkCoinsFolder:GetChildren() do
                coinSpawn.Transparency = 1

                local chance = coinSpawn:GetAttribute("Chance") or 100
                if math.random(1, 100) <= chance then
                    local coin = propsFolder.Coin:Clone()
                    coin.Position = coinSpawn.Position
                    coin.AlignPosition.Position = coin.Position
                    coin.Parent = chunkCoinsFolder

                    assetsFolder.CoinSound:Clone().Parent = coin

                    -- Copy behavior
                    coin:SetAttribute("Behavior", coinSpawn:GetAttribute("Behavior"))
                    coinSpawn:SetAttribute("Behavior", nil)
                end

                coinSpawn:Destroy()
            end
        end
        
        -- Dynamically add obstacles
        local chunkObstaclesFolder = chunk:FindFirstChild("Obstacles")
        if chunkObstaclesFolder then
            for _, obstacleSpawn in next, chunkObstaclesFolder:GetChildren() do
                obstacleSpawn.Transparency = 1

                local obstacle = obstaclesFolder:FindFirstChild(obstacleSpawn.Name)
                if not obstacle then continue end
    
                -- Spawn obstacle
                obstacle = obstacle:Clone()
                obstacle:PivotTo(obstacleSpawn.CFrame)
                obstacle.Parent = chunkObstaclesFolder
            end
        end

        -- Handle obstacle hitboxes
        for _, hitbox in next, chunk:GetDescendants() do
            if hitbox:IsA("BasePart") then
                local behavior = hitbox:GetAttribute("Behavior")

                if behavior then
                    local callback = Behaviors[hitbox:GetAttribute("Behavior")]
                    if callback then
                        callback(hitbox)
                    end
                end
            end
        end
        
        -- Parent and store chunk
        local rawName = chunk.Name
        chunk:SetAttribute("RawName", rawName)
        chunk.Name = self.ChunkID
        chunk.Parent = currentChunksFolder

        table.insert(self.Chunks, chunk)
        self.ChunkID += 1

        -- Remove chunk if too many
        if #self.Chunks > (self.Const.ChunksAhead + self.Const.ChunksBehind + 1) then
            self:RemoveLastChunk()
        end

        -- On chunk loaded event
        ReplicatedStorage.OnChunkLoaded:FireAllClients(rawName, chunk)

        -- Return chunk
        return chunk
    end
    
    function Path:RemoveLastChunk()
        if #self.Chunks < 1 then return end

        self.Chunks[1]:Destroy()
        table.remove(self.Chunks, 1)
    end

    function Path:CloseOtherBranches()
        -- TODO: Implement
    end

    function Path:CheckExtendPath()
        local chunk = self.Chunks[#self.Chunks - self.Const.ChunksAhead + 1]
        if not chunk then
            return
        end

        local baseStart = chunk:WaitForChild("BaseStart")
        local shouldExtend = player.Character.PrimaryPart.Position.Z < baseStart.Position.Z

        if shouldExtend then
            local chunk = self.Chunks[#self.Chunks - self.Const.ChunksAhead + 1]
            assert(chunk, "Last chunk not found")

            -- Spawn shop
            if math.random(1, 100) == 1 then
                self:GenerateUpgradeShop()
            end

            -- Extend path with new chunk
            self:GenerateChunk(chunksFolder.Plains.JumpPad)
        end
    end

    function Path:SetBiome(biome: any)
        self.Biome = biome
        self.BiomeChunkCount = 0
        warn("New biome: " .. biome.Name)
    end

    function Path:CheckChangeBiome()
        if self.BiomeChunkCount < self.Biome.Const.MinChunkAmount or math.random(0, 100) > self.Const.BiomeChangeChance then
            return
        end

        -- Get unique biomes
        local biomes = {}
        for _, biome in next, Biomes.Biomes do
            if biome ~= self.Biome then
                biomes[#biomes + 1] = biome
            end
        end
        assert(#biomes > 0, "No biomes to change to")

        -- Change biome
        local newBiome = biomes[math.random(1, #biomes)]
        self:SetBiome(newBiome)

        -- Generate biome transition chunk
        -- self:GenerateChunk(chunksFolder.Universal.BiomeTransition)
    end

    function Path:GeneratePathAsPlayerMoves()
        local extendPathConnection; extendPathConnection = RunService.Heartbeat:Connect(function()
            self:CheckExtendPath()
        end)
    
        player.CharacterRemoving:Connect(function() extendPathConnection:Disconnect() end)
        player.Character.Humanoid.Died:Connect(function() extendPathConnection:Disconnect() end)
    end

    function Path:TrackPlayerDistance(origin: Vector3)
        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then
            warn("Leaderstats not found")
            return
        end

        local trackDistanceConnection; trackDistanceConnection = RunService.Heartbeat:Connect(function()
            -- Calculate horizontal distance
            local playerPos = player.Character.PrimaryPart.Position
            local distance = math.max(0, (Vector3.new(0, 0, playerPos.Z) - Vector3.new(0, 0, origin.Z)).Magnitude * studsToMetersFactor)

            -- Update distance
            leaderstats.Distance.Value = distance

            -- Update highscore
            if distance > leaderstats.Highscore.Value then
                leaderstats.Highscore.Value = distance
            end
        end)
    
        player.CharacterRemoving:Connect(function() trackDistanceConnection:Disconnect() end)
        player.Character.Humanoid.Died:Connect(function()
            trackDistanceConnection:Disconnect()
        
            -- Update deaths
            leaderstats.Deaths.Value += 1
        end)
    end

    function Path:Init()
        -- Generate spawn platform
        local spawnChunk = self:GenerateChunk(chunksFolder[self.Biome.Name].SpawnPlatform)

        -- Generate initial chunks
        for _ = 1, self.Const.ChunksAhead do
            self:GenerateChunk()
        end

        local spawnPoint = spawnChunk:FindFirstChild("SpawnPoint")

        -- Teleport player to spawn platform
        player.Character:PivotTo(spawnPoint.CFrame)

        for _, attachment in next, spawnPoint:GetChildren() do
            if attachment:IsA("Attachment") then
                attachment:Clone().Parent = player.Character.PrimaryPart
            end
        end

        -- Track player distance
        self:TrackPlayerDistance(spawnPoint.Position)
    end

    function Path:GenerateUpgradeShop()
        local shopChunk = self:GenerateChunk(chunksFolder.Universal.UpgradeShop)
        local partsFolder = shopChunk:WaitForChild("Parts")
        local stopPart = partsFolder:WaitForChild("StopPart")

        -- Detect player touch to stop
        local stopTouched; stopTouched = stopPart.Touched:Connect(function(hit)
            if hit:IsA("BasePart") and hit.Parent == player.Character then
                stopTouched:Disconnect()
                ReplicatedStorage.ToggleShop:FireClient(player, true)
            end
        end)
    end

    function Path:Destroy()
        for _, chunk in next, self.Chunks do
            chunk:Destroy()
        end
    end

    -- Initialization
    Path:GeneratePathAsPlayerMoves()

    return Path
end