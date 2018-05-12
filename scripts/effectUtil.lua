effectUtil={}

function effectUtil.effectAllInRange(range,effect,duration)
	return effectUtil.effectNonPlayersInRange(range,effect,duration) + effectUtil.effectPlayersInRange(range,effect,duration)
end

function effectUtil.effectNonPlayersInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(effectUtil.getPos(),range),world.monsterQuery(effectUtil.getPos(),range))
	local rVal=0
	for _,id in pairs(buffer) do
		if effectUtil.effectTarget(id,effect,duration) then
			rVal=rVal+1
		end
	end
	return rVal
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
		world.sendEntityMessage(id,"applyStatusEffect",effect,duration,effectUtil.getSelf())
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

function effectUtil.effectOnSource(effect,duration,force)
	local source=effect and effect.sourceEntity and effect.sourceEntity() or effectUtil.source or nil
	if source then
		return effectUtil.effectTarget(source,effect,duration)
	elseif force then
		return effectUtil.effectSelf(effect,duration)
	else
		if not sourceWarning then
			sb.logInfo("effectUtil: effectOnSource needs effectUtil.source to be set in init to function.")
			sourceWarning=true
		end
	end
	return false
end

function effectUtil.messageParticle(position, text, color, size, offset, duration, layer)
	world.spawnProjectile("invisibleprojectile", position, 0, {0,0}, false,  {
        timeToLive = 0, damageType = "NoDamage", actionOnReap =
        {
            {
                action = "particle",
                specification = {
                    text =  text or "default Text",
                    color = color or {255, 255, 255, 255},  -- white
                    destructionImage = "/particles/acidrain/1.png",
                    destructionAction = "fade", --"shrink", "fade", "image" (require "destructionImage")
                    destructionTime = duration or 0.8,
                    layer = layer or "front",   -- 'front', 'middle', 'back' 
                    position = offset or {0, 2},
                    size = size or 0.7,  
                    approach = {0,20},    -- dunno what it is
                    initialVelocity = {0, 0.8},   -- vec2 type (x,y) describes initial velocity
                    finalVelocity = {0,0.5},
                    -- variance = {initialVelocity = {3,10}},  -- 'jitter' of included parameter
                    angularVelocity = 0,                                   
                    flippable = false,
                    timeToLive = duration or 2,
                    rotation = 0,
                    type = "text"                 -- our best luck
                }
            } 
        }
    }
    )
end

function effectUtil.say(sentence)
	if world.entityType(effectUtil.getSelf()) =="npc" then
		world.callScriptedEntity(effectUtil.getSelf(),"npc.say",sentence)
	elseif  world.entityType(effectUtil.getSelf())=="monster" then
		world.callScriptedEntity(effectUtil.getSelf(),"monster.say",sentence)
	else
		effectUtil.messageParticle(effectUtil.getPos(),sentence)
	end
end

function effectUtil.entityTypeName()
	return npc and npc.npcType() or monster and monster.type or entity and entity.entityType()
end