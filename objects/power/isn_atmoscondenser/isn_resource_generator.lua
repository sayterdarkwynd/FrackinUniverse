require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"

-- You might notice there's no timer here.
-- The time between outputs and power consumption is determined by
-- the object's "scriptDelta".

function init()
    transferUtil.init()
    object.setInteractive(true)
    self.powerConsumption = config.getParameter("isn_requiredPower")
    power.init()

    -- Set up output here so it won't take up time later
    local outputConfig = config.getParameter("outputs")
    local outputTable = outputConfig[world.type()] or outputConfig["default"]
    if type(outputTable) == "string" then
        outputTable = outputConfig[outputTable]
    end
    local weights = config.getParameter("namedWeights")
    self.maxWeight = 0
    self.outputMap = {}
    for _,table in ipairs(outputTable or {}) do
        local weight = weights[table.weight] or table.weight
        self.maxWeight = self.maxWeight + weight
        self.outputMap[weight] = table.items
    end
end

function update(dt)
    power.update(dt)
    local output = nil
    local rarityroll = math.random(1, self.maxWeight)

    -- Goes through the list adding values to the range as it goes.
    -- This keeps the chance ratios while allowing the list to be in any order.
    local total = 0
    for weight,table in pairs(self.outputMap) do
        total = total + weight
        if rarityroll <= total then
            output = util.randomFromList(table)
            break
        end
    end

    if output and clearSlotCheck(output) and power.consume(self.powerConsumption) then
        animator.setAnimationState("machineState", "active")
        world.containerAddItems(entity.id(), output)
    else
        animator.setAnimationState("machineState", "idle")
    end
end

function clearSlotCheck(checkname)
  return world.containerItemsCanFit(entity.id(), checkname) > 0
end
