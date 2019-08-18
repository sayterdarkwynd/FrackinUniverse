effectUtil={}

function effectUtil.getPos()
	return ((entity and entity.position) and entity.position()) or ((activeItem and activeItem.ownerAimPosition) and activeItem.ownerAimPosition()) or {0,0}
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




function effectUtil.effectTypesInRange(effect,range,types,duration,teamType)
	if type(effect)~="string" then
		return 0
	end
	local pos=effectUtil.getPos()
	local buffer=world.entityQuery(pos,range,{includedTypes=types})
	local rVal=0
	teamType=teamType or "all"

	for _,id in pairs(buffer) do
		if teamType == "all" then
			if effectUtil.effectTarget(id,effect,duration) then
				rVal=rVal+1
			end
		else
			local teamData=world.entityDamageTeam(id)
			if teamData.type==teamType then
				if effectUtil.effectTarget(id,effect,duration) then
					rVal=rVal+1
				end
			end
		end
	end
	return rVal
end

function effectUtil.effectAllInRange(effect,range,duration)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration)
end

function effectUtil.effectAllOfTeamInRange(effect,range,duration,team)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,team)
end

function effectUtil.effectAllEnemiesInRange(effect,range,duration)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,"enemy")
end

function effectUtil.effectAllFriendliesInRange(effect,range,duration)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,"friendly")
end

function effectUtil.effectNonPlayersInRange(effect,range,duration)
	return effectUtil.effectTypesInRange(effect,range,{"npc","monster"},duration)
end

function effectUtil.effectPlayersInRange(effect,range,duration)
	return effectUtil.effectTypesInRange(effect,range,{"player"},duration)
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

function effectUtil.projectileTypesInRange(projtype,tilerange,types)
	local targetlist = world.entityQuery(entity.position(),tilerange,{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype, world.entityPosition(value), entity.id())
	end
end

function effectUtil.projectilePlayersInRange(projtype,tilerange)
	effectUtil.projectileTypesInRange(projtype,tilerange,{"player"})
end

function effectUtil.projectileAllInRange(projtype,tilerange)
	effectUtil.projectileTypesInRange(projtype,tilerange,{"creature"})
end

function effectUtil.projectileTypesInRangeParams(projtype,tilerange,params,types)
	local targetlist = world.entityQuery(entity.position(),tilerange,{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype, world.entityPosition(value), entity.id(),{0,0},false,params)
	end
end

function effectUtil.projectilePlayersInRangeParams(projtype,tilerange,params)
	effectUtil.projectileTypesInRangeParams(projtype,tilerange,params,{"player"})
end

function effectUtil.projectileAllInRangeParams(projtype,tilerange,params)
	effectUtil.projectileTypesInRangeParams(projtype,tilerange,params,{"creature"})
end

function effectUtil.projectileTypesInRectangle(projtype,entpos,xwidth,yheight,types)
	local targetlist = world.entityQuery(entpos,{entpos[1]+xwidth, entpos[2]+yheight},{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype,world.entityPosition(value))
	end
end

function effectUtil.projectilePlayersInRectangle(projtype,entpos,xwidth,yheight)
	effectUtil.projectileTypesInRectangle(projtype,entpos,xwidth,yheight,{"player"})
end

function effectUtil.projectileAllInRectangle(projtype,entpos,xwidth,yheight)
	effectUtil.projectileTypesInRectangle(projtype,entpos,xwidth,yheight,{"creature"})
end