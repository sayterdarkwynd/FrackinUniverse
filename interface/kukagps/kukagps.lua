-- THIS IS THE FRACKIN RACES ONE
require "/scripts/util.lua"

MATERIALS = "materialList.materials"

function init()
        populateMaterialsList()
end

function addText(text)
	local path = string.format("%s.%s.text", MATERIALS, widget.addListItem(MATERIALS))
	widget.setText(path, text)
end

function addSeparator()
        addText("-------------------------------------------------------------------------------")
end

function populateMaterialsList()
        widget.clearListItems(MATERIALS)
        local worldId = string_split(player.worldId(),":")
        local planet = {location = {tonumber(worldId[2]),tonumber(worldId[3]),tonumber(worldId[4])}, planet = tonumber(worldId[5]), satellite = (tonumber(worldId[6]) or 0)}
        local system ={location = {tonumber(worldId[2]),tonumber(worldId[3]),tonumber(worldId[4])}}

        if worldId[1]=="InstanceWorld" then
            addText("This is an Instance World")

            -- More info about the dungeon could be added here
        elseif worldId[1]=="ClientShipWorld" then
                addText("This is a Ship World")

                local shipInfo = player.shipUpgrades()
                local isBYOS = world.getProperty("fu_byos")

                if isBYOS then
                    addText("^green;Ship type:^reset; BYOS (Build Your Own Ship)")
                    addText("Can be expanded by mining the exterior of the ship. There are no upgrade quests.")

                    if (world.getProperty("fu_byos.systemTravel") or 0) > 0 then
                        addText("^green;Engine status^reset;: fully operational ^yellow;FTL drive^reset; (can travel anywhere).")
                    elseif (world.getProperty("fu_byos.planetTravel") or 0) > 0 then
                        addText("^green;Engine status^reset;: ^yellow;STL drive^reset; (can travel within the system).")
                        addText("Replace with ^yellow;Small FTL drive^reset; to travel to other systems.")
                        addText("Note: travel within the system (regardless of engine) doesn't use fuel.")
                    else
                        addText("^green;Engine status^reset;: ^red;inactive^reset; (no working engine detected).")
                        addText("Can be repaired by placing either ^yellow;STL Drive^reset; or ^yellow;Small FTL Drive^reset; anywhere on the ship.")
                    end
                else
                    addText("^green;Ship type:^reset; Vanilla ship (not BYOS)")

                    local shipLevel = shipInfo.shipLevel or 0
                    addText("^green;Ship tier:^reset; " .. shipLevel)

                    if not contains(player.shipUpgrades().capabilities, "systemTravel") then
                        addText("^green;Engine status^reset;: ^red;inactive^reset; (not repaired).")
                        addText("Ship will be immediately repaired upon meeting Esther Bright on the vanilla Outpost.")
                    else
                        addText("^green;Engine status^reset;: ^yellow;fully operational^reset;.")
                        if shipLevel < 8 then
                            addText("Upgraded the same way as in vanilla (either ^yellow;crew^reset; or ^yellow;licenses^reset;).")
                        else
                            addText("Maximum size reached (ship can't be expanded further).")
                        end
                    end
                end

                addSeparator()

                addText(string.format(
                    "^green;Fuel cost discount:^reset; %.f%%",
                    100 * (shipInfo.fuelEfficiency or 0)
                ))
                addText("^green;Max fuel:^reset; " .. (shipInfo.maxFuel or '?'))
                addText("^green;Ship speed (within the system):^reset; " .. (shipInfo.shipSpeed or '?'))

                -- TODO: add information about the crew limits, etc.
        elseif worldId[1]=="CelestialWorld" then
            dungeons =root.assetJson("/interface/kukagps/dungeons.config")
            weather =root.assetJson("/interface/kukagps/weather.config")
            enviroment =root.assetJson("/interface/kukagps/enviroment.config")
            ores =root.assetJson("/interface/kukagps/ores.config")
            biomes =root.assetJson("/interface/kukagps/biomes.config")
            stars =root.assetJson("/interface/kukagps/stars.config")

            -- print system
            addText("^green;System:^reset; "..celestial.planetName(system))

            local starType = celestial.planetParameters(system).typeName or "default"
            -- print star
            addText("^green;Star:^reset; " .. (stars[starType] or '?'))

            -- print coord
            addText("^green;Coordinate X:^reset; "..system.location[1].."                        ^green;Coordinate Y:^reset; "..system.location[2])

            -- print planet
            addText("^green;Planet:^reset; "..celestial.planetName(planet))

            -- print planet primary biome
            local parameters = celestial.visitableParameters(planet)
            addText("                                                ^green;BIOMES:^reset; ")

            local forbiddenBiomes={"atropuselder","atropuselderunderground","elder","elderunderground","precursorsurface","precursorunderground","shoggothbiome"}
            local anomaliesFound=false
            local worldSize = world.size() or {0,0}

            -- Search for biomes.
            local function showLayer(layer, layerName, layerAbove, biomeColors)
                if not layer then return end

                local biomeCodes = {
                    layer.primaryRegion.biome,
                    layer.primarySubRegion.biome
                }
                for _, region in pairs(layer.secondaryRegions) do
                    table.insert(biomeCodes, region.biome)
                end
                for _, region in pairs(layer.secondarySubRegions) do
                    table.insert(biomeCodes, region.biome)
                end

                -- Remove duplicates, but preserve the order.
                local uniqueBiomeCodes = {}
                local alreadyListed = {}
                for _, biomeCode in ipairs(biomeCodes) do
                    if not alreadyListed[biomeCode] then
                        table.insert(uniqueBiomeCodes, biomeCode)
                        alreadyListed[biomeCode] = true
                    end
                end

                local listedBiomeNames = {}
                for _, biomeCode in ipairs(uniqueBiomeCodes) do
                    if BiomeCheck(forbiddenBiomes, biomeCode) then
                        -- Semi-secret biomes like Precursor Underground are not listed.
                        anomaliesFound = true
                    else
                        local biomeName = biomes[biomeCode] or biomeCode
                        local biomeColor = biomeColors and biomeColors[biomeCode]
                        if biomeColor then
                            biomeName = string.format("^%s;%s^reset;", biomeColor, biomeName)
                        end

                        table.insert(listedBiomeNames, biomeName)
                    end
                end

                local biomesDescription
                if #listedBiomeNames == 0 then
                    -- The only biome is secret. Not really secret in this situation...
                    biomesDescription = '(scans inconclusive)'
                else
                    biomesDescription = table.concat(listedBiomeNames, ', ') .. '.'
                end

                local value = string.format("^green;%s^reset; [%s-%s]: %s",
                    layerName,
                    layer.layerMinHeight,
                    layerAbove and layerAbove.layerMinHeight or worldSize[2],
                    biomesDescription
                )
                addText(value)
            end

            showLayer(parameters.spaceLayer, "Space Layer")
            showLayer(parameters.atmosphereLayer, "Atmosphere Layer", parameters.spaceLayer)
            if parameters.surfaceLayer then
                showLayer(parameters.surfaceLayer, "Surface Layer", parameters.atmosphereLayer,
                    { [parameters.surfaceLayer.primaryRegion.biome] = "yellow" }
                )
            end
            showLayer(parameters.subsurfaceLayer, "SubSurface Layer", parameters.surfaceLayer)

            local layerAboveCore
            if parameters.undergroundLayers then
                showLayer(parameters.undergroundLayers[1], "Underground Layer 1", parameters.subsurfaceLayer)
                showLayer(parameters.undergroundLayers[2], "Underground Layer 2", parameters.undergroundLayers[1])
                showLayer(parameters.undergroundLayers[3], "Underground Layer 3", parameters.undergroundLayers[2])
                layerAboveCore = parameters.undergroundLayers[#parameters.undergroundLayers]
            end
            showLayer(parameters.coreLayer, "Core Layer", layerAboveCore or parameters.subsurfaceLayer)

            -- anomalies found?
            if anomaliesFound then
                addText("^red;Some anomalies were found on those layers....^reset; ")
            end

            local pos = world.entityPosition(player.id())
            -- print pos
            addText("^green;Position X:^reset; "..math.floor(pos[1]).."                                       ^green;Position Y:^reset; "..math.floor(pos[2]))

            -- print world size
            addText("^green;Width:^reset; "..worldSize[1].."                                            ^green;Height:^reset; "..worldSize[2])

            -- print planet threat and gravity
            addText(string.format("^green;Planet tier / Threat:^reset; %.2f", parameters.threatLevel))
            addText("^green;Gravity:^reset; "..(parameters.gravity or 0))

            -- print planet ores names
            addText("^green;Ores:^reset; ")
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
                    addText("       "..localOres)
                    localOres = "None"
                    linecount = 0
                end
            end
            if linecount ~= 0 then
                localOres = localOres.."."
                addText("       "..localOres)
            end

            addSeparator()

            if parameters.primaryBiome then -- asteroid fields don't have time in the typical sense
                -- print date
                addText("^green;Date:^reset; "..getDate(world.day()))

                -- print time
                addText("^green;Time:^reset; "..timeConversion())

                -- print day length
                addText("^green;Day Length:^reset; "..math.floor(world.dayLength()))
            end

            -- print light level
            local lightLevel = math.floor(world.lightLevel(world.entityPosition(player.id()))*100)/100
            addText("^green;Light Level:^reset; "..lightLevel)

            -- print windLevel
            local windLevel = math.floor(world.windLevel(world.entityPosition(player.id()))*100)/100
            addText("^green;Wind Level:^reset; "..windLevel)

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

            addSeparator()

            enviro = enviro.."."
            addText("^green;Enviroment Status Effects:^reset; "..enviro)

            addSeparator()

            addText("^green;Weather:^reset; ")

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
                    addText("          "..weatherItem)  -- print a long tab space, and then a line of weather info
                    weatherItem = "None"
                    linecount = 0
                end
            end
            if linecount ~= 0 then
                weatherItem = weatherItem.."."
                addText("          "..weatherItem)
            end

            addSeparator()

            -- print dungeons
            addText("^green;Dungeons on Planet:^reset; ")

            -- Search for dungeons in spaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.spaceLayer and parameters.spaceLayer.dungeons) then
                for _,dungeon in pairs(parameters.spaceLayer.dungeons) do
                    addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                end
            end
            -- Search for dungeons in atmosphereLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.atmosphereLayer and parameters.atmosphereLayer.dungeons) then
                for _,dungeon in pairs(parameters.atmosphereLayer.dungeons) do
                    addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                end
            end
            -- Search for dungeons in surfaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.surfaceLayer and parameters.surfaceLayer.dungeons) then
                for _,dungeon in pairs(parameters.surfaceLayer.dungeons) do
                    addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                end
            end
            -- Search for dungeons in subsurfaceLayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.subsurfaceLayer and parameters.subsurfaceLayer.dungeons) then
                for _,dungeon in pairs(parameters.subsurfaceLayer.dungeons) do
                    addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                end
            end
            -- Search for dungeons in undergroundLayers. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.undergroundLayers) then
                for _,layer in pairs(parameters.undergroundLayers) do
                    -- you have to go in every layer inside undergroundLayers
                    for _,dungeon in pairs(layer.dungeons) do
                        addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                    end
                end
            end
            -- Search for dungeons in corelayer. If exists in dungeon's list, look for name. Else, unknown dungeon.
            if (parameters.coreLayer and parameters.coreLayer.dungeons) then
                for _,dungeon in pairs(parameters.coreLayer.dungeons) do
                    addText(dungeons[dungeon] or "Unknown["..dungeon.."]")
                end
            end
        else
            -- no ship, no dungeon/instance and no world.......Where the fuck are you?
            addText("This is a ERROR")
        end
end

-- contribution of zimberzimber
function string_split(str, pat)
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
    local month=1
    local daysperyear=365.242
	local year = math.floor(days / daysperyear)
	days = math.floor(days % daysperyear)
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

-- check list of biomes already printed
function BiomeCheck(tbl, biome)
    for _, value in pairs(tbl) do
        if (value == biome) then
            return true
        end
    end
    return false
end
