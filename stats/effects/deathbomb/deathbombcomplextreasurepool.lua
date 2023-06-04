require "/scripts/util.lua"

function init()
	if not world.entityType(entity.id()) then return end
	canExplode=false
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or (not world.entityExists(entity.id())) or ((world.entityType(entity.id())== "monster") and (world.callScriptedEntity(entity.id(),"getClass") == 'bee')) then
		return
	end
	poolData=config.getParameter("poolData")
	entType=world.entityType(entity.id())
	if poolData then
		if not blocker then blocker=config.getParameter("blocker","deathbombcomplextreasurepool") end
		if entType=="monster" then
			local minBaseHealth=config.getParameter("minBaseHealth",10)
			local eConfig=root.monsterParameters(world.entityTypeName(entity.id()))
			subType=eConfig.bodyMaterialKind or status.statusProperty("targetMaterialKind") or (eConfig.statusSettings and eConfig.statusSettings.statusProperties and eConfig.statusSettings.statusProperties.targetMaterialKind)
			if minBaseHealth then
				local baseHealth=eConfig.statusSettings and eConfig.statusSettings.stats and eConfig.statusSettings.stats.maxHealth and eConfig.statusSettings.stats.maxHealth.baseValue or 0
				if baseHealth > minBaseHealth then
					--subType=eConfig.bodyMaterialKind
					canExplode=true
				end
			else
				--subType=eConfig.bodyMaterialKind
				canExplode=true
			end
		elseif entType=="npc" then
			subType=world.entitySpecies(entity.id())
			canExplode=true
		end
	else
		sb.logInfo("deathbombcomplextreasurepool: missing pool data on status effect!")
	end
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	if canExplode and (status.resourcePercentage("health") <= 0.05) and not status.statPositive("deathbombDud") then
		explode()
	end
end

function uninit()
end

function explode()
	if not blocker then blocker=config.getParameter("blocker","deathbombcomplextreasurepool") end
	if not exploded then
		if not status.statPositive(blocker) and poolData then
			local stub=poolData[entType] and poolData[entType][subType] or poolData[entType] and poolData[entType]["default"] or poolData["default"]
			status.addPersistentEffect(blocker,{stat=blocker,amount=1})
			world.spawnTreasure(entity.position(),stub,world.threatLevel())
		end
		canExplode=false
		exploded = true
	end
end