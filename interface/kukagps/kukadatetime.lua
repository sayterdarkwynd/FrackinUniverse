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
                    weather =root.assetJson("/interface/kukagps/weather.config")
                    enviroment =root.assetJson("/interface/kukagps/enviroment.config")
                    
                    -- print date
                    local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Date:^reset; "..getDate(world.day()))

                    -- print time
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Time:^reset; "..timeConversion())

                    -- print day length
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Day Length:^reset; "..math.floor(world.dayLength()))

                    -- print light level
                    local lightLevel = math.floor(world.lightLevel(world.entityPosition(player.id()))*100)/100
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Light Level:^reset; "..lightLevel)

                    -- print windLevel
                    local windLevel = math.floor(world.windLevel(world.entityPosition(player.id()))*100)/100
                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Wind Level:^reset; "..windLevel)

                    local parameters = celestial.visitableParameters(planet)
                    -- print enviroment status effects
                    local enviro="None"
                    for _,env in pairs(parameters.environmentStatusEffects) do
                        if enviro=="None" then
                            enviro = enviroment[env] or env
                        else
                            enviro = enviro..", "..(enviroment[env] or env)
                        end
                    end
                    enviro = enviro.."."

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Enviroment Status Effects:^reset; "..enviro)

                    path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                    widget.setText(path .. ".text", "^green;Weather:^reset; ")

                    local weatherItem="None"
                    local linecount=0
                    for _,w in pairs(parameters.weatherPool) do
                        ww = (w.weight * 100)
                        if weatherItem=="None" then
                            weatherItem = (weather[w.item] or w.item).."("..ww.."%)"
                        else
                            weatherItem = weatherItem..", "..(weather[w.item] or w.item).."("..ww.."%)"
                        end
                        linecount = linecount+1
                        if linecount==4 then
                            -- print line and reset counter
                            weatherItem = weatherItem.."."
                            local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                            widget.setText(path .. ".text", "          "..weatherItem)
                            weatherItem = "None"
                            linecount = 0
                        end
                    end
                    if linecount ~= 0 then
                        weatherItem = weatherItem.."."
                        local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
                        widget.setText(path .. ".text", "          "..weatherItem)
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
