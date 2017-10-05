require '/scripts/power.lua'
local crafting = false
local output = nil

function init()
	power.init()
	self = config.getParameter("duplicator")
	self.timer = self.craftTime
end

function update(dt)
	--if wireCheck() == true then
		if crafting == false then
		if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
			local slot = 0
			local fuelSlot = getInputContents(slot)
			for _,fuel in pairs (self.fuel) do
				if fuelSlot == fuel then
					slot = 1
					local inputOutputSlot = getInputContents(slot)
					for _,inputOutput in pairs (self.inputOutput) do
						if inputOutputSlot == inputOutput then
							world.containerConsumeAt(entity.id(),0,1)
							self.timer = self.craftTime
							output = inputOutputSlot
							crafting = true
						end
					end
				end
			end
		end
		end
	--end
	self.timer = self.timer - dt
	if self.timer <= 0 then
		if crafting == true then
			if power.consume(config.getParameter('isn_requiredPower')) then
				local slots = getOutSlotsFor(output)
				for _,i in pairs(slots) do
					output = world.containerPutItemsAt(entity.id(), output, i)
					if output == nil then
						break
					end
				end
				if output ~= nil then
					world.spawnItem(output, entity.position(), 1)
				end
				crafting = false
			end
		end
	end
	if not crafting and self.timer <= 0 then
		self.timer = self.craftTime
	end
	power.update(dt)
end

function getInputContents(slot)
	local stack = world.containerItemAt(entity.id(),slot)
	local contents = {}
	if stack then
		contents = stack.name
	end
	return contents
end

function wireCheck()
	if object.isInputNodeConnected(0) == true then
		if object.getInputNodeLevel(0) == true then
			return true
		else
			return false
		end
	else
	return true
	end
	return false
end

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
end