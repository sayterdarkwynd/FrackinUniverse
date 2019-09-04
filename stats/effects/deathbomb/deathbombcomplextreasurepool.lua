require "/scripts/util.lua"

function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) then
		effect.expire()
	end
	
	poolData=config.getParameter("poolData")
	entType=world.entityType(entity.id())
	canExplode=(not (status.resourceMax("health") < config.getParameter("minMaxHealth", 0))) and poolData
	
	if not canExplode then return end
	
	if entType=="monster" then
		local eConfig=root.monsterParameters(world.entityTypeName(entity.id()))
		subType=eConfig.bodyMaterialKind
	elseif entType=="npc" then
		subType=world.entitySpecies(entity.id())
	end
end

function update(dt)
	if canExplode and not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
		explode()
	end
end

function uninit()
end

function explode()
	if not exploded then
		if poolData then
			local stub=poolData[entType] and poolData[entType][subType] or poolData[entType] and poolData[entType]["default"] or poolData["default"]
			world.spawnTreasure(entity.position(),stub,world.threatLevel())
		end
		exploded = true
	end
end