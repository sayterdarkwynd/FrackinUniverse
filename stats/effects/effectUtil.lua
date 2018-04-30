effectUtil={}

function effectUtil.effectAllInRange(range,effect,duration)
	return effectUtil.effectNonPlayersInRange(range,effect,duration) + effectUtil.effectPlayersInRange(range,effect,duration)
end

function effectUtil.effectNonPlayersInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(effectUtil.getPos(),range),world.monsterQuery(entity.position(),range))
	local rVal=0
	for _,id in pairs(buffer) do
		if effectUtil.effectTarget(id,effect,duration) then
			rVal=rVal+1
		end
	end
end

function effectUtil.effectPlayersInRange(range,effect,duration)
	local buffer=world.playerQuery(effectUtil.getPos(),range)
	local rVal=0
	for _,id in pairs(buffer) do
		if effectUtil.effectTarget(id,effect,duration) then
			rVal=rVal+1
		end
	end
	return rVal
end

function effectUtil.effectSelf(effect,duration)
	return effectUtil.effectTarget(effectUtil.getSelf(),effect,duration)
end

function effectUtil.effectTarget(id,effect,duration)
	if world.entityExists(id) then
		world.sendEntityMessage(id,"applyStatusEffect",effect,duration,entity.id())
		return true
	else
		return false
	end
end

function effectUtil.getPos()
	return (entity and entity.position and entity.position()) or (activeItem and activeItem.ownerAimPosition and activeItem.ownerAimPosition()) or {0,0}
end

function effectUtil.getSelf()
	return entity and entity.id and entity.id() or activeItem and activeItem.ownerEntityId() or nil
end

function effectUtil.effectOnSource(effect,duration)
	local source=effect and effect.sourceEntity and effect.sourceEntity() or nil
	if source then
		effectUtil.effectTarget(source,effect,duration)
		return true
	end
	return false
end