-- THIS IS THE FRACKIN RACES ONE
require "/scripts/util.lua"

MATERIALS = "materialList.materials"

function init()
        populateMaterialsList()
end

function populateMaterialsList()
        //sb.logInfo("WID: "..player.worldId())
        widget.clearListItems(MATERIALS)
        local worldId = string.split(player.worldId(),":")
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
                    ores =root.assetJson("/interface/kukagps/ores.config")
                    planets =root.assetJson("/interface/kukagps/planets.config")
                    stars =root.assetJson("/interface/kukagps/stars.config")	

                    local system = celestial.currentSystem()
                    -- print system
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;System:^reset; "..celestial.planetName(system))

                    local starType = celestial.planetParameters(system).typeName or "default"
                    -- print star
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Star:^reset; "..stars[starType])

                    -- print coord
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Coordinate X:^reset; "..system.location[1].."                        ^green;Coordinate Y:^reset; "..system.location[2])

                    local planet = {location = {tonumber(worldId[2]),tonumber(worldId[3]),tonumber(worldId[4])}, planet = tonumber(worldId[5]), satellite = (tonumber(worldId[6]) or 0)}
                    -- print planet
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Planet:^reset; "..celestial.planetName(planet))

                    -- print planet type
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Type:^reset; "..planets[world.type()])

                    local pos = world.entityPosition(player.id())
                    -- print pos
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Position X:^reset; "..pos[1].."                        ^green;Position Y:^reset; "..pos[2])

                    local size = world.size() or {0,0}
                    -- print world size        
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Width:^reset; "..size[1].."                        ^green;Height:^reset; "..size[2])

                    -- print planet type
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Threat:^reset; "..(world.threatLevel() or 0).."                        ^green;Gravity:^reset; "..world.gravity(world.entityPosition(player.id())) or 0)

                    -- print planet ores
                    local localOres="0"
                    for _,ore in pairs(celestial.planetOres(celestial.shipLocation()[2], (world.threatLevel() or 0))) do
                        if localOres=="0" then
                            localOres = (ores[ore] or ore)
                        else
                            localOres = localOres..", "..(ores[ore] or ore)
                        end            
                    end
                    localOres = localOres.."."
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Ores:^reset; "..localOres)
                else
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "This is a ERROR")
                end
            end
        end
end

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
