require '/scripts/power.lua'
require '/scripts/util.lua'

local crafting = false
local output = nil

function init()
	power.init()
	self = config.getParameter("duplicator")
	self.craftTime = config.getParameter("craftTime")
	self.timer = self.craftTime
end

function update(dt)
	local fuelSlot = world.containerItemAt(entity.id(),1)
	fuelSlot = fuelSlot and fuelSlot.name or ""

	local inputOutputSlot = world.containerItemAt(entity.id(),0)
	inputOutputSlot = inputOutputSlot and inputOutputSlot.name or ""

	local fuelValue=self.fuel[fuelSlot] or 0
	local fuelValueBonus = 0  -- bonus output

	if wireCheck() == true and fuelValue > 0 then -- make sure there is fuel in there
		if crafting == false then
			if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
			animator.setAnimationState("base", "on")
				if contains(self.inputOutput,inputOutputSlot) then
					world.containerConsumeAt(entity.id(),1,1)
					self.timer = self.craftTime
					output = inputOutputSlot

					--sb.logInfo("%s",root.itemConfig(inputOutputSlot))
					itemOre = root.itemConfig(world.containerItemAt(entity.id(),0))

					if itemOre then
					  if math.random(10) == 10 then
					    fuelValueBonus = math.random(1,2)
					  end

					  itemValue = itemOre.config.price /1000
					  fuelValue = (fuelValue - (fuelValue  * itemValue)) + fuelValueBonus
					  if fuelValue < 1 then
					    fuelValue = 1
					  end
					end

					outputCount = fuelValue
					crafting = true
				end
			end
		end
	end
	if self.timer <= 0 then
		if crafting == true then

			if power.consume(config.getParameter('isn_requiredPower')) then

				--local slots = getOutSlotsFor(output)
				output = world.containerPutItemsAt(entity.id(), {name=output,count=outputCount}, 2)

				if output then
					output=world.containerPutItemsAt(entity.id(), output, 0)
				end
				
				if output then
					world.spawnItem(output, entity.position())
					output=nil
				end
				
				crafting = false
			end
		else
		  animator.setAnimationState("base", "off")
		end
	end

	self.timer = self.timer - dt
	if not crafting and self.timer <= 0 then
	  self.timer = 0
	end

	power.update(dt)
end

function wireCheck()
	return (object.inputNodeCount() >= 1) or not object.isInputNodeConnected(0) or object.getInputNodeLevel(1)
end

--[[
function getOutSlotsFor(something)
    local empty = {} -- empty slots in the outputs
    local slots = {} -- slots with a stack of "something"

    for i = 2, 2 do -- iterate all output slots
        local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
        if stack ~= nil then -- not empty
            if stack.name == something then -- its "something"
                table.insert(slots,i) -- possible drop slot
            end
        else -- empty
            table.insert(empty, i)
        end
    end

    for _,e in pairs(empty) do -- add empty slots to the end
        table.insert(slots,e)
    end
    return slots
end]]