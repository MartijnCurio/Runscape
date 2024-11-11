local Biomes = {
    KeyNames = {
        "Plains",
        "Desert",
        "Snowy"
    },
    Biomes = {}
}

-- Generate dynamic biome constants
for _, biomeName in next, Biomes.KeyNames do
    Biomes.Biomes[biomeName] = {
        Name = biomeName,
        Const = {
            MinChunkAmount = 10
        },
        IgnoreList = {}
    }
end

-- Add biome specific ignore lists
table.insert(Biomes.Biomes.Plains.IgnoreList, "SpawnPlatform")

return Biomes