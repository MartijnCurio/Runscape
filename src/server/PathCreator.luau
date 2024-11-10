-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
local CurrentChunksFolder = workspace:WaitForChild("CurrentChunks")
local ChunksFolder = ReplicatedStorage:WaitForChild("Chunks")

-- Main
return function(player: Player)
    local Path = {
        Const = {
            ChunksAhead = 3,
            ChunksBehind = 3,
            BiomeNames = {
                "Plains",
                "Desert",
                "Snowy"
            },
            ChunkIgnoreList = {
                "SpawnPlatform"
            }
        },
        Biome = "Plains",
        Chunks = {},
        ChunkID = 0
    }

    function Path:GenerateChunk(chunkName: string?): Instance
        local chunk;

        -- Obtain chunk by name or randomly
        if chunkName == nil then
            -- Change biome
            if math.random(1, 1) == 1 then
                self.Biome = self.Const.BiomeNames[math.random(1, #self.Const.BiomeNames)]
            end

            warn("Biome: " .. self.Biome)

            local biomeFolder = ChunksFolder:FindFirstChild(self.Biome)
            assert(biomeFolder, "Biome folder not found")
            
            -- Populate chunks table
            local chunks = {}
            for _, chunk in next, biomeFolder:GetChildren() do
                if not table.find(self.Const.ChunkIgnoreList, chunk.Name) then
                    table.insert(chunks, chunk)
                end
            end
            assert(#chunks > 0, "No chunks found")

            -- Get random chunk
            chunk = chunks[math.random(1, #chunks)]:Clone()
        else
            -- Get chunk by name
            chunk = ChunksFolder:FindFirstChild(chunkName, true):Clone()
        end
        assert(chunk, "Chunk not found")
        
        -- Position chunk
        local currentChunks = CurrentChunksFolder:GetChildren()
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
        chunk.Parent = CurrentChunksFolder        
        table.insert(self.Chunks, chunk)

        self.ChunkID += 1

        -- Remove chunk if too many
        if #self.Chunks > (self.Const.ChunksAhead + self.Const.ChunksBehind + 1) then
            self:RemoveChunk()
        end

        return chunk
    end

    function Path:RemoveChunk()
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

    function Path:Init()
        -- Generate spawn platform
        local spawnChunk = self:GenerateChunk("SpawnPlatform")

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