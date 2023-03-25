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
                if ((selectedCatalyst.count)<=(items[2].count)) then   
                    local itemConfig = root.itemConfig(stemsample)
                    local mergeBuffer={}
                    local stages=stemsample.parameters.stages or itemConfig.config.stages
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
                    saplingLevel = stemsample.parameters.saplingLevel or 0
                    mergeBuffer.description = itemConfig.config.description.."\nModified sapling (^green;"..(saplingLevel+1).."^reset;)\n Time (^green;"..minDuration.."^reset;/^green;"..maxDuration.."^reset;)"
                    mergeBuffer.saplingLevel = saplingLevel+1
                    mergeBuffer.stages = stages
                    if(canConsume)then
                        if(world.containerConsumeAt(entity.id(),1,selectedCatalyst.count))then
                            stemsample.parameters=util.mergeTable(copy(stemsample.parameters),copy(mergeBuffer))
                            world.containerTakeAt(entity.id(),0)
                            world.containerPutItemsAt(entity.id(),stemsample,2)
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
            if ((selectedCatalyst.count)<=(items[2].count)) then                
                local itemConfig = root.itemConfig(seedsample)
                local mergeBuffer={}
                local stages=seedsample.parameters.stages or itemConfig.config.stages
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
                seedLevel = seedsample.parameters.seedLevel or 0
                mergeBuffer.description = itemConfig.config.description.."\nModified seed (^green;"..(seedLevel+1).."^reset;)\n Time (^green;"..minDuration.."^reset;/^green;"..maxDuration.."^reset;)"
                mergeBuffer.seedLevel = seedLevel+1
                mergeBuffer.stages = stages
                if(canConsume)then
                    if(world.containerConsumeAt(entity.id(),1,selectedCatalyst.count))then
                        seedsample.parameters=util.mergeTable(copy(seedsample.parameters),copy(mergeBuffer))
                        world.containerTakeAt(entity.id(),0)
                        world.containerPutItemsAt(entity.id(),seedsample,2)
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

function die()
end
