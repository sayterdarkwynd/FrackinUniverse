require '/scripts/power.lua'
require '/scripts/util.lua'

function init()
	power.init()
	self = config.getParameter("duplicator")
	self.craftTime = config.getParameter("craftTime")
	storage.timer = storage.timer or self.craftTime -- making this, storage.crafting, etc. persistent so that on server terminus, nothing is lost.
	math.randomseed(os.time())
end

function update(dt)
	local fuelSlot = world.containerItemAt(entity.id(),1)

	local inputSlot = world.containerItemAt(entity.id(),0)
	inputSlot = inputSlot and inputSlot.name or ""

	local fuelValue=self.fuel[fuelSlot and fuelSlot.name or ""] or 0
	local fuelValueBonus = 0  -- bonus output

	if not storage.crafting then--no point doing further comparisons unless we actually need them.
		if wireCheck() then -- logic wires on? neutronium and antineutronium in?
			if fuelValue > 0 then -- fueled?
				if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
					animator.setAnimationState("base", "on")
					
					if contains(self.inputs,inputSlot) then
						storage.fuelTaken=fuelSlot --recorded for potential refund later
						storage.fuelTaken.count=1
						world.containerConsumeAt(entity.id(),1,1)
						storage.timer = self.craftTime
						storage.output = inputSlot
						local fuelMod = self.fuel[inputSlot] and 0.5 or 1
						
						--sb.logInfo("%s",root.itemConfig(inputSlot))
						itemOre = root.itemConfig(world.containerItemAt(entity.id(),0))

						if itemOre then

							itemValue = itemOre.config.price /1000
							fuelValue = (fuelValue - (fuelValue * itemValue)) + (math.random() * 0.1)
							
							local fuelValueDecimals=(fuelValue%1)*fuelMod*fuelMod
							fuelValue=math.max(fuelValue*fuelMod,1)
							
							if fuelValueDecimals>0 then
								fuelValue=math.floor(fuelValue)
								if math.random() < fuelValueDecimals then
									fuelValue=fuelValue+1
								end
							end
						end
						storage.outputCount = fuelValue
						storage.crafting = true
					end
				end
			end
		end
	end
	
	if storage.timer <= 0 then
		if storage.crafting then

			if wireCheck() and power.consume(config.getParameter('isn_requiredPower')) then -- added option for a hard abort that won't eat materials
				--local slots = getOutSlotsFor(storage.output)
				storage.output = world.containerPutItemsAt(entity.id(), {name=storage.output,count=storage.outputCount}, 4)

				if storage.output then
					storage.output=world.containerPutItemsAt(entity.id(), storage.output, 0)
				end
				
				if storage.output then
					world.spawnItem(storage.output, entity.position())
					storage.output=nil
				end
				
				storage.fuelTaken=nil
				storage.crafting = false
			else
				--if we can't get power, we just chuck the fuel back into the hopper (or on the ground). and stop animating.
				animator.setAnimationState("base", "off")
				storage.fuelTaken = world.containerPutItemsAt(entity.id(), storage.fuelTaken, 1)
				if storage.fuelTaken then
					world.spawnItem(storage.fuelTaken, entity.position())
					storage.fuelTaken=nil
				end
				--stop crafting. nil values.
				storage.output=nil
				storage.crafting=false
			end
		else
			animator.setAnimationState("base", "off")
		end
	end

	storage.timer = storage.timer - dt
	if not storage.crafting and storage.timer <= 0 then
		storage.timer = 0
	end

	power.update(dt)
end

function wireCheck()
	--since we're only really using them here these neutronium parts got added here. can easily be moved out if needed.
	local neutronium = world.containerItemAt(entity.id(),2)
	neutronium=neutronium and (neutronium.name=="neutronium")
	
	local antineutronium = world.containerItemAt(entity.id(),3)
	antineutronium=antineutronium and (antineutronium.name=="antineutronium")
	
	return (neutronium and antineutronium) and (object.inputNodeCount() < 1 or not object.isInputNodeConnected(0) or object.getInputNodeLevel(0))
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