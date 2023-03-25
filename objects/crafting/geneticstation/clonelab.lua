require "/scripts/util.lua"

function init()
    cloningPrep()
    storage.bannedFoliage = config.getParameter("bannedFoliage")
    storage.bannedStems = config.getParameter("bannedStems")
end

function cloningPrep()
    if self.hasPrepped == false then
        storage.heldItems = world.containerItems(entity.id())
        self.pause = false
        self.hasPrepped = true
    end
end

function containerCallback()
    seeds = root.assetJson("/objects/crafting/geneticstation/seeds.config")
    bees = root.assetJson("/objects/crafting/geneticstation/bees.config")
    catalyst = root.assetJson("/objects/crafting/geneticstation/catalyst.config")

    local items = world.containerItems(entity.id())
    
    if items[1]~=null and items[1].name == "sapling" then
        if items[2]~=null and catalyst[items[2].name] then
            local stemsample = items[1]
            if checkBanlist(stemsample, stemsample) then
                local selectedCatalyst = catalyst[items[2].name]
                if (selectedCatalyst.count<=items[2].count) then                
                    local itemConfig = root.itemConfig(stemsample)
                    local mergeBuffer={}
                    local stages=itemConfig.config.stages
                    local description = itemConfig.config.description
                    local descArray = string_split(description,"\n")
                    if(descArray[2])then
                        -- is modified sapling
                        local tempArray = string_split(descArray[2],"(")
                        local saplingLevel = string_split(tempArray[2],")")
                    end    
                    local minDuration=0
                    local maxDuration=0
                    local canConsume=false
                    for k,v in pairs(stages) do
                        if (v.duration) and (itemConfig.config.stages[k].duration) then
                            local newDuration1 = v.duration[1]-selectedCatalyst.value
                            local newDuration2 = v.duration[2]-selectedCatalyst.value
                            if(newDuration1>(itemConfig.config.stages[k].duration[1]/2))then
                                v.duration[1] = newDuration1
                                minDuration = minDuration+newDuration1
                                canConsume=true
                            end
                            if(newDuration2>(itemConfig.config.stages[k].duration[2]/2))then
                                v.duration[2] = newDuration2
                                maxDuration = maxDuration+newDuration2
                            end
                        end   
                    end
                    if(saplingLevel)then
                        mergeBuffer.description = descArray[1].."\n^green;Modified sapling ("..saplingLevel[1]..")^reset;\n Time ("..minDuration.."/"..maxDuration..")"
                    else
                        mergeBuffer.description = descArray[1].."\n^green;Modified sapling (1)^reset;\n Time ("..minDuration.."/"..maxDuration..")"
                    end
                    mergeBuffer.stages = stages
                    if(canConsume)then
if(world.containerConsumeAt(entity.id(),2,10))then
                            stemsample.parameters=util.mergeTable(copy(stemsample.parameters),copy(mergeBuffer))
                            world.containerTakeAt(entity.id(),0)
                            world.containerPutItemsAt(entity.id(),stemsample,0)
                        end
                    end
                end
            end
        end
    elseif items[1]~=null and seeds[items[1].name] then
        if items[2]~=null and catalyst[items[2].name] then
            -- seed combination        
            local seedsample = items[1]
            local selectedCatalyst = catalyst[items[2].name]
            if (selectedCatalyst.count<=items[2].count) then                
                local itemConfig = root.itemConfig(seedsample)
                local mergeBuffer={}
                local stages=itemConfig.config.stages
                local description = itemConfig.config.description
                local descArray = string_split(description,"\n")
                if(descArray[2])then
                    -- is modified seed
                    local tempArray = string_split(descArray[2],"(")
                    local seedLevel = string_split(tempArray[2],")")
                end    
                local minDuration=0
                local maxDuration=0
                local canConsume=false
                for k,v in pairs(stages) do
                    if (v.duration) and (itemConfig.config.stages[k].duration) then
                        local newDuration1 = v.duration[1]-selectedCatalyst.value
                        local newDuration2 = v.duration[2]-selectedCatalyst.value
                        if(newDuration1>(itemConfig.config.stages[k].duration[1]/2))then
                            v.duration[1] = newDuration1
                            minDuration = minDuration+newDuration1
                            canConsume=true
                        end
                        if(newDuration2>(itemConfig.config.stages[k].duration[2]/2))then
                            v.duration[2] = newDuration2
                            maxDuration = maxDuration+newDuration2
                        end
                    end   
                end
                if(seedLevel)then
                    mergeBuffer.description = descArray[1].."\n^green;Modified seed ("..seedLevel[1]..")^reset;\n Time ("..minDuration.."/"..maxDuration..")"
                else
                    mergeBuffer.description = descArray[1].."\n^green;Modified seed (1)^reset;\n Time ("..minDuration.."/"..maxDuration..")"
                end
                mergeBuffer.stages = stages
                if(canConsume)then
                    if(world.containerConsumeAt(entity.id(),2,10))then
                        seedsample.parameters=util.mergeTable(copy(seedsample.parameters),copy(mergeBuffer))
                        world.containerTakeAt(entity.id(),0)
                        world.containerPutItemsAt(entity.id(),seedsample,0)
                    end
                end
            end
        end
    elseif items[1]~=null and bees[items[1].name] then
        if items[2]~=null and catalyst[items[2].name] then
            -- bee improvement
            -- TODO
        end
    end
end

function checkBanlist(stemsample, stemsample)
    local leaf = stemsample.parameters["foliageName"]
    local stem = stemsample.parameters["stemName"]

    for _, bannedLeaf in ipairs(storage.bannedFoliage) do
        if leaf == bannedLeaf then
            return false
        end
    end
    for _, bannedStem in ipairs(storage.bannedStems) do
        if stem == bannedStem then
            return false
        end
    end
    return true
end

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

function die()
end
