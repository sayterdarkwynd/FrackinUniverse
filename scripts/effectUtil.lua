effectUtil={}

function effectUtil.getPos()
	return ((entity and entity.position) and entity.position()) or ((activeItem and activeItem.ownerAimPosition) and activeItem.ownerAimPosition()) or {0,0}
end

function effectUtil.getSelf()
	return entity and entity.id and entity.id() or activeItem and activeItem.ownerEntityId() or nil
end

function effectUtil.getSelfType()
	return world.entityType(effectUtil.getSelf())
end

function effectUtil.effectOnSource(effect,duration,force,source)
	local effectSource=effect and effect.sourceEntity and effect.sourceEntity() or effectUtil.source or nil
	if effectSource then
		return effectUtil.effectTarget(effectSource,effect,duration,source)
	elseif force then
		return effectUtil.effectSelf(effect,duration,source)
	else
		if not sourceWarning then
			sb.logInfo("effectUtil: effectOnSource needs effectUtil.source to be set in init to function.")
			sourceWarning=true
		end
	end
	return false
end

function effectUtil.messageParticle(position, text, color, size, offset, duration, layer)
	world.spawnProjectile("invisibleprojectile", position, 0, {0,0}, false, {
		timeToLive = 0, damageType = "NoDamage", actionOnReap =
			{
				{
					action = "particle",
					specification = {
						text =	text or "default Text",
						color = color or {255, 255, 255, 255},	-- white
						destructionImage = "/particles/acidrain/1.png",
						destructionAction = "fade", --"shrink", "fade", "image" (require "destructionImage")
						destructionTime = duration or 0.8,
						layer = layer or "front",	 -- 'front', 'middle', 'back'
						position = offset or {0, 2},
						size = size or 0.7,
						approach = {0,20},		-- dunno what it is
						initialVelocity = {0, 0.8},	 -- vec2 type (x,y) describes initial velocity
						finalVelocity = {0,0.5},
						-- variance = {initialVelocity = {3,10}},	-- 'jitter' of included parameter
						angularVelocity = 0,
						flippable = false,
						timeToLive = duration or 2,
						rotation = 0,
						type = "text"	-- our best luck
					}
				}
			}
		}
	)
end

function effectUtil.say(sentence)
	local selfType=effectUtil.getSelfType()
	if selfType =="npc" then
		world.callScriptedEntity(effectUtil.getSelf(),"npc.say",sentence)
	elseif selfType=="monster" then
		world.callScriptedEntity(effectUtil.getSelf(),"monster.say",sentence)
	else
		effectUtil.messageParticle(effectUtil.getPos(),sentence)
	end
end

function effectUtil.entityTypeName()
	return npc and npc.npcType() or monster and monster.type or entity and entity.entityType()
end

function effectUtil.effectTypesInRange(effect,range,types,duration,teamType,source)
	if type(effect)~="string" then
		return 0
	end
	local pos=effectUtil.getPos()
	local rVal=0
	if effectUtil.getSelfType()=="player" then
		local data={}
		data.messageFunctionArgs={effect,range,types,duration,teamType,source}
		data.messenger=effectUtil.getSelf()
		world.spawnStagehand(pos,"effectUtilStarryPyHelper",{messageData=data})
	else
		local buffer=world.entityQuery(pos,range,{includedTypes=types or {"creature"}})
		teamType=teamType or "all"

		for _,id in pairs(buffer) do
			if teamType == "all" then
				if effectUtil.effectTarget(id,effect,duration,source) then
					rVal=rVal+1
				end
			else
				local validTypes=entity and entity.entityType and {monster=true,npc=true,player=true,currentType=entity.entityType()}
				local valid=validTypes and validTypes[validTypes["currentType"]] and (entity.isValidTarget and entity.isValidTarget(id))
				local teamData={}
				if valid==false then
					teamData.type="friendly"
				elseif valid == true then
					teamData.type="enemy"
				else
					teamData=world.entityDamageTeam(id)
				end

				if teamData.type==teamType then
					if effectUtil.effectTarget(id,effect,duration,source) then
						rVal=rVal+1
					end
				end
			end
		end
	end
	return rVal
end

function effectUtil.messageTypesInRange(effect,range,types,teamType,args)
	if type(effect)~="string" then
		return 0
	end
	local pos=effectUtil.getPos()
	local buffer=world.entityQuery(pos,range,{includedTypes=types or {"creature"}})
	local rVal=0
	teamType=teamType or "all"

	for _,id in pairs(buffer) do
		if teamType == "all" then
			if args then
				if world.sendEntityMessage(id,effect,args:unpack()) then
					rVal=rVal+1
				end
			elseif world.sendEntityMessage(id,effect) then
				rVal=rVal+1
			end
		else
			local teamData=world.entityDamageTeam(id)
			if teamData.type==teamType then
				if args then
					if world.sendEntityMessage(id,effect,args:unpack()) then
						rVal=rVal+1
					end
				elseif world.sendEntityMessage(id,effect) then
					rVal=rVal+1
				end
			end
		end
	end
	return rVal
end

function effectUtil.messageMechsInRange(effect,range,args)
	if type(effect)~="string" then
		return 0
	end
	local pos=effectUtil.getPos()
	local buffer=world.entityQuery(pos,range,{includedTypes={"Vehicle"}})
	local rVal=0

	for _,id in pairs(buffer) do
		if world.entityName(id) == "modularmech" then
			if args then
				if world.sendEntityMessage(id,effect,args:unpack()) then
					rVal=rVal+1
				end
			elseif world.sendEntityMessage(id,effect) then
				rVal=rVal+1
			end
		end
	end
	return rVal
end

--effectUtil.effectTypesInRange(effect,range,types,duration,teamType,source)
function effectUtil.effectAllInRange(effect,range,duration,source)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,nil,source)
end

function effectUtil.effectAllOfTeamInRange(effect,range,duration,team,source)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,team,source)
end

function effectUtil.effectAllEnemiesInRange(effect,range,duration,source)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,"enemy",source)
end

function effectUtil.effectAllFriendliesInRange(effect,range,duration,source)
	return effectUtil.effectTypesInRange(effect,range,{"creature"},duration,"friendly",source)
end

function effectUtil.effectNonPlayersInRange(effect,range,duration,source)
	return effectUtil.effectTypesInRange(effect,range,{"npc","monster"},nil,duration,source)
end

function effectUtil.effectPlayersInRange(effect,range,duration,source)
	return effectUtil.effectTypesInRange(effect,range,{"player"},duration,nil,source)
end

function effectUtil.effectSelf(effect,duration,source)
	return effectUtil.effectTarget(effectUtil.getSelf(),effect,duration,source)
end

function effectUtil.effectTarget(id,effect,duration,source)
	if world.entityExists(id) then
		if not effect or effect=="" then
			return false
		else
			world.sendEntityMessage(id,"applyStatusEffect",effect,duration,source or effectUtil.getSelf())
			return true
		end
	else
		return false
	end
end

function effectUtil.projectileSelf(projtype,params)
--sb.logInfo("%s",{pt=projtype, ep=entity.position(), ei=entity.id(), p=params})
--EntityId world.spawnProjectile(String projectileName, Vec2F position, [EntityId sourceEntityId], [Vec2F direction], [bool trackSourceEntity], [Json parameters])
	world.spawnProjectile(projtype, entity.position(), entity.id(),nil,nil, params)
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