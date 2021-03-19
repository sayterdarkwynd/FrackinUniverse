-- THIS IS THE FRACKIN RACES ONE
require "/scripts/util.lua"

MATERIALS = "materialList.materials"

function init()
        populateMaterialsList()
end

function populateMaterialsList()
        widget.clearListItems(MATERIALS)
        local worldId = string.split(player.worldId(),":")
        local planet = {location = {tonumber(worldId[2]),tonumber(worldId[3]),tonumber(worldId[4])}, planet = tonumber(worldId[5]), satellite = (tonumber(worldId[6]) or 0)}
        local system ={location = {tonumber(worldId[2]),tonumber(worldId[3]),tonumber(worldId[4])}}
        if worldId[1]=="InstanceWorld" then
            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
            widget.setText(path .. ".text", "This is a Instance World. Instance World do not contain relevant GPS data. Please travel to a planet surface.")
            -- More info about the dungeon could be added here
        else
            if worldId[1]=="ClientShipWorld" then
                local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                widget.setText(path .. ".text", "This is a Ship World. Ship Worlds do not contain relevant GPS data. Please travel to a planet surface.")
                -- More info about the ship could be added here
            else
                if worldId[1]=="CelestialWorld" then
                    ores =root.assetJson("/interface/kukagps/ores.config")
                    biomes =root.assetJson("/interface/kukagps/biomes.config")
                    stars =root.assetJson("/interface/kukagps/stars.config")

                    -- local system = celestial.currentSystem()
                    -- print system
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;System:^reset; "..celestial.planetName(system))

                    local starType = celestial.planetParameters(system).typeName or "default"
                    -- print star
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Star:^reset; "..stars[starType])

                    -- print coord
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Coordinate X:^reset; "..system.location[1].."               ^green;Coordinate Y:^reset; "..system.location[2])

                    -- print planet
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Planet:^reset; "..celestial.planetName(planet))

                    -- print planet primary biome
                    local parameters = celestial.visitableParameters(planet)
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Primary biome:^reset; "..biomes[parameters.primaryBiome] or parameters.primaryBiome)

                    local subbiomes="None"
                    for key,subBiome in pairs(parameters.surfaceLayer.secondarySubRegions) do
                        if subBiome and subBiome.biome ~= parameters.primaryBiome then
                            if subbiomes=="None" then
                                subbiomes = biomes[subBiome.biome]
                            else
                                subbiomes = subbiomes..", "..biomes[subBiome.biome]
                            end
                        end
                    end
                    subbiomes = subbiomes.."."
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Secondary biomes:^reset; "..subbiomes)

                    local pos = world.entityPosition(player.id())
                    -- print pos
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Position X:^reset; "..math.floor(pos[1]).."                             ^green;Position Y:^reset; "..math.floor(pos[2]))

                    local size = world.size() or {0,0}
                    -- print world size
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Width:^reset; "..size[1].."                                 ^green;Height:^reset; "..size[2])

                    -- print planet threat
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Threat:^reset; "..ThreatToString(world.threatLevel()).."                        ^green;Gravity:^reset; "..world.gravity(world.entityPosition(player.id())) or 0)

                    -- print planet ores
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Ores:^reset; ")
                    local localOres="None"
                    local linecount=0
                    for _,ore in pairs(celestial.planetOres(planet, (world.threatLevel() or 0))) do
                        if localOres=="None" then
                            localOres = (ores[ore] or ore)
                        else
                            localOres = localOres..", "..(ores[ore] or ore)
                        end
                        linecount = linecount+1
                        if linecount==7 then
                            -- print line and reset counter
                            localOres = localOres.."."
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", "       "..localOres)
                            localOres = "None"
                            linecount = 0
                        end
                    end
                    if linecount ~= 0 then
                        localOres = localOres.."."
                        local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "       "..localOres)
                    end
                else
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "This is a ERROR")
                end
            end
        end
end

-- contribution of zimberzimber
strs = {
    "Harmless (I)",
    "Low (II)",
    "Moderate (III)",
    "Risky (IV)",
    "Dangerous (V)",
    "Extreme (VI)",
    "Lethal (VII)",
    "Impossible (VIII)",
    "Immeasurable (IX)",
    "Just No (X)",
    "No (XI)",
}

function ThreatToString(threat)
    local floored = math.max(math.floor(threat) + 1, 1)
    return strs[floored] or strs[#strs]
end
-- contribution of zimberzimber

function string.split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
        end
        if last_end <= #str then
            cap = str:sub(last_end)
            table.insert(t, cap)
        end
        return t
end
