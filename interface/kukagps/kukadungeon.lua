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
                    dungeons =root.assetJson("/interface/kukagps/dungeons.config")

                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Dungeons on Planet:^reset; ")

                    local parameters = celestial.visitableParameters(planet)
                    if (parameters.spaceLayer and parameters.spaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.spaceLayer.dungeons) do
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    if (parameters.atmosphereLayer and parameters.atmosphereLayer.dungeons) then
                        for _,dungeon in pairs(parameters.atmosphereLayer.dungeons) do
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    if (parameters.surfaceLayer and parameters.surfaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.surfaceLayer.dungeons) do
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    if (parameters.subsurfaceLayer and parameters.subsurfaceLayer.dungeons) then
                        for _,dungeon in pairs(parameters.subsurfaceLayer.dungeons) do
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
                    if (parameters.undergroundLayers) then
                        for _,layer in pairs(parameters.undergroundLayers) do
                            for _,dungeon in pairs(layer.dungeons) do
                                local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                                widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                            end
                        end
                    end
                    if (parameters.coreLayer and parameters.coreLayer.dungeons) then
                        for _,dungeon in pairs(parameters.coreLayer.dungeons) do
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", dungeons[dungeon] or "Unknown["..dungeon.."]")
                        end
                    end
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
