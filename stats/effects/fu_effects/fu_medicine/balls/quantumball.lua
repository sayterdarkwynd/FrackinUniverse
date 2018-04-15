require "/scripts/util.lua"

function init()
	
end

function update(dt)

end

function effectInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(activeItem.ownerAimPosition(),range),world.monsterQuery(entity.position(),range))
	for _,id in pairs(buffer) do
		--world.sendEntityMessage(id,"applyStatusEffect",effect,duration,activeItem.ownerEntityId())
		effectTarget(id,effect,duration)
	end
end

function effectSelf(effect,duration)
	effectTarget(entity.id(),effect,duration)
end

function effectTarget(id,effect,duration)
	world.sendEntityMessage(id,"applyStatusEffect",effect,duration,entity.id())
end