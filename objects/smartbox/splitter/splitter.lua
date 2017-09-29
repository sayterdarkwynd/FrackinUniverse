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
		local stack = world.containerTakeNumItemsAt(id, 0, (input.count // size) * size)
		if stack then 
			stack = world.containerPutItemsAt(id, stack, slot)
			if stack then
				world.containerPutItemsAt(id, stack, 0)
				if ((stack.count or 0) % size) ~= 0 then
					stack = world.containerTakeNumItemsAt(id, slot, size - (stack.count % size))
					world.containerPutItemsAt(id, stack, 0)
				end
			end
		end
	end
end
