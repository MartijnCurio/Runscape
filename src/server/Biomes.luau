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
            MinChunkAmount = 20
        },
        IgnoreList = {
            "SpawnPlatform"
        }
    }
end

return Biomes