require "/scripts/kheAA/transferUtil.lua"
local deltaTime = 0

function init()
	transferUtil.init()
	object.setInteractive(true)
end

function update(dt)
	deltaTime = deltaTime + dt
	if deltaTime > 1 then
		deltaTime = 0
		transferUtil.loadSelfContainer()
	end
	refresh(100, 1)
	refresh(10, 2)
	refresh(1, 3)
end

function refresh(size, slot)
	local id = entity.id()
	local input = world.containerItemAt(id, 0)
	if input then
		local output = world.containerItemAt(id, slot)
		local oldnum = 0
		if output then
			oldnum = output.count or oldnum
		end
		local stack = world.containerTakeNumItemsAt(id, 0, (input.count // size) * size)
		if stack then 
			stack = world.containerPutItemsAt(id, stack, slot)
			if stack then
				world.containerPutItemsAt(id, stack, 0)
			end
		end
		output = world.containerItemAt(id, slot)
		if output then
			local difnum = ((output.count or 0) /2) % size
			if difnum ~= 0 then
				stack = world.containerTakeNumItemsAt(id, slot, difnum)
				world.containerPutItemsAt(id, stack, 0)
			end
		end
	end
end
