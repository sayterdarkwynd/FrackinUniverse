require "/scripts/kheAA/transferUtil.lua"

function init()
	object.setInteractive(true)
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	refresh()
end

function refresh()
	local id = entity.id()
	local input = world.containerItemAt(id, 0)
	if input then
		local half = world.containerTakeNumItemsAt(id, 0, (input.count // 2))
		local rest = world.containerTakeAt(id, 0)
		if half then
			local stack = world.containerPutItemsAt(id, half, 1)
			if stack then
				world.containerPutItemsAt(id, stack, 0)
				stack = world.containerTakeNumItemsAt(id, 1, half.count - (stack.count or 0))
				if stack then
					world.containerPutItemsAt(id, stack, 0)
				end
			end
		end
		if rest then
			local stack = world.containerPutItemsAt(id, rest, 2)
			if stack then
				world.containerPutItemsAt(id, stack, 0)
				stack = world.containerTakeNumItemsAt(id, 2, rest.count - (stack.count or 0))
				if stack then
					world.containerPutItemsAt(id, stack, 0)
				end
			end
		end
	end
end