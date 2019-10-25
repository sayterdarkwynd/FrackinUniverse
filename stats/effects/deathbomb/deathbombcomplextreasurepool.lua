require "/scripts/util.lua"

function init()
	canExplode=false
	if (status.resourceMax("health") >= config.getParameter("minMaxHealth", 0)) then
		poolData=config.getParameter("poolData")
		entType=world.entityType(entity.id())
		if poolData then
			if entType=="monster" then
				local minBaseHealth=config.getParameter("minBaseHealth",10)
				local eConfig=root.monsterParameters(world.entityTypeName(entity.id()))
				
				if minBaseHealth then
					local baseHealth=eConfig.statusSettings and eConfig.statusSettings.stats and eConfig.statusSettings.stats.maxHealth and eConfig.statusSettings.stats.maxHealth.baseValue or 0
					if baseHealth > minBaseHealth then
						subType=eConfig.bodyMaterialKind
						canExplode=true
					end
				else
					subType=eConfig.bodyMaterialKind
					canExplode=true
				end
			elseif entType=="npc" then
				subType=world.entitySpecies(entity.id())
				canExplode=true
			end
		else
			sb.logInfo("deathbombcomplextreasurepool: missing pool data on status effect!")
		end
	end
end

function update(dt)
	if canExplode and not status.resourcePositive("health") then
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