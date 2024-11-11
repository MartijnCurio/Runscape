-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
local currentChunksFolder = workspace:WaitForChild("CurrentChunks")
local chunksFolder = ReplicatedStorage:WaitForChild("Chunks")

local Biomes = require(script.Parent:WaitForChild("Biomes"))

-- Main
return function(player: Player)
    local Path = {
        Const = {
            ChunksAhead = 5,
            ChunksBehind = 5,
            BiomeChangeChance = 20
        },
        Biome = Biomes.Biomes.Plains,
        Chunks = {},
        ChunkID = 0,
        BiomeChunkCount = 0
    }

    function Path:GenerateChunk(selectedChunk: Instance?): Instance
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

        -- Position chunk
        local currentChunks = currentChunksFolder:GetChildren()
        if #currentChunks > 0 then
            local lastChunk = currentChunks[#currentChunks]
            local lastChunkEnd = lastChunk:WaitForChild("ChunkEnd")
            local finalCFrame = lastChunkEnd.CFrame
            chunk:PivotTo(finalCFrame)
        else
            chunk:PivotTo(CFrame.new())
        end

        -- Parent and store chunk
        chunk.Name = self.ChunkID
        chunk.Parent = currentChunksFolder

        table.insert(self.Chunks, chunk)
        self.ChunkID += 1

        -- Remove chunk if too many
        if #self.Chunks > (self.Const.ChunksAhead + self.Const.ChunksBehind + 1) then
            self:RemoveLastChunk()
        end

        -- Return chunk
        return chunk
    end
    
    function Path:RemoveLastChunk()
        assert(#self.Chunks > 0, "No chunks to remove")

        self.Chunks[1]:Destroy()
        table.remove(self.Chunks, 1)
    end

    function Path:CheckExtendPath()
        local chunk = self.Chunks[#self.Chunks - self.Const.ChunksAhead + 1]
        assert(chunk, "No chunk to check")

        local chunkStart = chunk:WaitForChild("ChunkStart")
        local shouldExtend = player.Character.PrimaryPart.Position.Z < chunkStart.Position.Z

        if shouldExtend then
            warn("Extending path")
            self:GenerateChunk()
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

        local biomes = {}
        for _, biome in next, Biomes.Biomes do
            if biome ~= self.Biome then
                biomes[#biomes + 1] = biome
            end
        end
        assert(#biomes > 0, "No biomes to change to")

        local newBiome = biomes[math.random(1, #biomes)]
        self:SetBiome(newBiome)
    end

    function Path:Init()
        -- Generate spawn platform
        local spawnChunk = self:GenerateChunk(chunksFolder.Plains.SpawnPlatform)

        -- Generate initial chunks
        for _ = 1, self.Const.ChunksAhead do
            self:GenerateChunk()
        end

        local spawnPoint = spawnChunk:FindFirstChild("SpawnPoint")

        -- Teleport player to spawn platform
        player.Character:PivotTo(spawnPoint.CFrame)
    end

    function Path:GeneratePathAsPlayerMoves()
        local extendPathConnection; extendPathConnection = RunService.Heartbeat:Connect(function()
            self:CheckExtendPath()
        end)
    
        player.CharacterRemoving:Connect(function() extendPathConnection:Disconnect() end)
        player.Character.Humanoid.Died:Connect(function() extendPathConnection:Disconnect() end)
    end

    -- Add path as player moves
    Path:GeneratePathAsPlayerMoves()

    return Path
end