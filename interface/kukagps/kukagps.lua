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
            widget.setText(path .. ".text", "This is a Instance World")
            -- More info about the dungeon could be added here
        else
            if worldId[1]=="ClientShipWorld" then
                local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                widget.setText(path .. ".text", "This is a Ship World")
                -- More info about the ship could be added here
            else
                if worldId[1]=="CelestialWorld" then
                    dungeons =root.assetJson("/interface/kukagps/dungeons.config")
                    weather =root.assetJson("/interface/kukagps/weather.config")
                    enviroment =root.assetJson("/interface/kukagps/enviroment.config")
                    ores =root.assetJson("/interface/kukagps/ores.config")
                    biomes =root.assetJson("/interface/kukagps/biomes.config")
                    stars =root.assetJson("/interface/kukagps/stars.config")

                    -- print system
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;System:^reset; "..celestial.planetName(system))

                    local starType = celestial.planetParameters(system).typeName or "default"
                    -- print star
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Star:^reset; " .. (stars[starType] or '?'))

                    -- print coord
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Coordinate X:^reset; "..system.location[1].."                        ^green;Coordinate Y:^reset; "..system.location[2])

                    -- print planet
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Planet:^reset; "..celestial.planetName(planet))

                    -- print planet primary biome
                    local parameters = celestial.visitableParameters(planet)
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Primary biome:^reset; "..(parameters.primaryBiome and (biomes[parameters.primaryBiome] or parameters.primaryBiome) or (biomes[parameters.typeName] or parameters.typeName)))

                    -- print planet subbiomes (includes main biome)
                    local subbiomes="None"
                    if parameters.surfaceLayer then
                        for _,subBiome in pairs(parameters.surfaceLayer.secondarySubRegions) do
                            if subBiome and subBiome.biome ~= parameters.primaryBiome then
                                if subbiomes=="None" then
                                    subbiomes = biomes[subBiome.biome]
                                else
                                    subbiomes = subbiomes..", "..biomes[subBiome.biome]
                                end
                            end
                        end
                    end
                    subbiomes = subbiomes.."."

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Secondary biomes:^reset; "..subbiomes)

                    local pos = world.entityPosition(player.id())
                    -- print pos
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Position X:^reset; "..math.floor(pos[1]).."                                       ^green;Position Y:^reset; "..math.floor(pos[2]))

                    local size = world.size() or {0,0}
                    -- print world size
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Width:^reset; "..size[1].."                                            ^green;Height:^reset; "..size[2])

                    -- print planet threat and gravity
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Threat:^reset; "..ThreatToString(parameters.threatLevel).."                                   ^green;Gravity:^reset; "..parameters.gravity or 0)

                    -- print planet ores names
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Ores:^reset; ")
                    local localOres="None"
                    local linecount=0
                    for _,ore in pairs(celestial.planetOres(planet, (parameters.threatLevel or 0))) do
                        if localOres=="None" then
                            localOres = (ores[ore] or ore)
                        else
                            localOres = localOres..", "..(ores[ore] or ore)
                        end
                        linecount = linecount+1
                        if linecount==7 then
                            -- print line and reset counter
                            localOres = localOres.."."
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", "       "..localOres)
                            localOres = "None"
                            linecount = 0
                        end
                    end
                    if linecount ~= 0 then
                        localOres = localOres.."."
                        path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "       "..localOres)
                    end

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "-------------------------------------------------------------------------------")

                    if parameters.primaryBiome then -- asteroid fields don't have time in the typical sense
                        -- print date
                        path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "^green;Date:^reset; "..getDate(world.day()))

                        -- print time
                        path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "^green;Time:^reset; "..timeConversion())

                        -- print day length
                        path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "^green;Day Length:^reset; "..math.floor(world.dayLength()))
                    end

                    -- print light level
                    local lightLevel = math.floor(world.lightLevel(world.entityPosition(player.id()))*100)/100
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Light Level:^reset; "..lightLevel)

                    -- print windLevel
                    local windLevel = math.floor(world.windLevel(world.entityPosition(player.id()))*100)/100
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Wind Level:^reset; "..windLevel)

                    -- print enviroment status effects
                    local enviro="None"
                    for _,env in pairs(parameters.environmentStatusEffects) do
                        if enviro=="None" then
                            -- its the first.    
                            enviro = enviroment[env] or env
                        else
                            -- its NOT the first. Add comma.
                            enviro = enviro..", "..(enviroment[env] or env)
                        end
                    end

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "-------------------------------------------------------------------------------")

                    enviro = enviro.."."
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Enviroment Status Effects:^reset; "..enviro)

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "-------------------------------------------------------------------------------")

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Weather:^reset; ")

                    local weatherItem="None"
                    linecount=0
                    for _,w in pairs(parameters.weatherPool) do
                        ww = (w.weight * 100)
                        if weatherItem=="None" then
                            -- its the first.
                            weatherItem = (weather[w.item] or w.item).."("..ww.."%)"
                        else
                            -- its NOT the first. Add comma.
                            weatherItem = weatherItem..", "..(weather[w.item] or w.item).."("..ww.."%)"
                        end
                        linecount = linecount+1
                        if linecount==4 then
                            -- after 4 elements, print line and reset counter
                            
                            weatherItem = weatherItem.."."
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", "          "..weatherItem)  -- print a long tab space, and then a line of weather info
                            weatherItem = "None"
                            linecount = 0
                        end
                    end
                    if linecount ~= 0 then
                        weatherItem = weatherItem.."."
                        path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "          "..weatherItem)
                    end

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "-------------------------------------------------------------------------------")

                    -- print dungeons
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Dungeons on Planet:^reset; ")

                    -- Search for dungeons in spaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.spaceLayer and parameters.spaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.spaceLayer.dungeons) do
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    -- Search for dungeons in atmosphereLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.atmosphereLayer and parameters.atmosphereLayer.dungeons) then
                        for _,dungeon in pairs(parameters.atmosphereLayer.dungeons) do
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    -- Search for dungeons in surfaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.surfaceLayer and parameters.surfaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.surfaceLayer.dungeons) do
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    -- Search for dungeons in subsurfaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.subsurfaceLayer and parameters.subsurfaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.subsurfaceLayer.dungeons) do
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    -- Search for dungeons in undergroundLayers. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.undergroundLayers) then
                        for _,layer in pairs(parameters.undergroundLayers) do
                            -- you have to go in every layer inside undergroundLayers               
                            for _,dungeon in pairs(layer.dungeons) do
                                path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                                widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                            end
                        end
                    end
                    -- Search for dungeons in corelayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
                    if (parameters.coreLayer and parameters.coreLayer.dungeons) then
                        for _,dungeon in pairs(parameters.coreLayer.dungeons) do
                            path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                else
                    -- no ship, no dungeon/instance and no world.......Where the fuck are you?    
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

function timeConversion()
        -- Hubnester time conversion function
        hubTime = (world.timeOfDay() + 0.25) * 24    -- the 0.25 is to make 0 am = 6 am (when the day starts)
        if hubTime > 12 then
            hubTime = hubTime - 12
            hubTimeModifier = " pm"
            if hubTime > 12 then
                hubTime = hubTime - 12
                hubTimeModifier = " am"
                if hubTime < 1 then
                    hubTime = hubTime + 12
                end
            elseif hubTime < 1 then
                hubTime = hubTime + 12
            end
        else
            hubTimeModifier = " am"
        end
        hubHours = math.floor(hubTime, 0)
        hubMinutes = math.floor((hubTime - hubHours) * 60)
        if hubMinutes < 10 then
            hubMinutes = "0" .. tostring(hubMinutes)
        end
        return tostring(hubHours) .. ":" .. tostring(hubMinutes) .. tostring(hubTimeModifier)
end

function getDate(days)
    local year=0
    local month=1
    local daysperyear=365
    while (days>=daysperyear) do
       daysperyear=365
       if ((year%4)==0) or (((year%100)==0) and ((year%400)==0)) then
          daysperyear=366
       end
       days=days-daysperyear
       year=year+1
    end
    local dayspermonth={31,28,31,30,31,30,31,31,30,31,30,31}
    if ((year%4)==0) or (((year%100)==0) and ((year%400)==0)) then
       dayspermonth={31,29,31,30,31,30,31,31,30,31,30,31}
    end
    while (days>=dayspermonth[month]) do
       days=days-dayspermonth[month]
       month=month+1
    end
    days=days+1
    return "Year "..year..", Month "..month.." and Day "..days
end
