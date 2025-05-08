require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/companions/util.lua"

function init()
	stages = config.getParameter("stages")
	farmingModConfig = root.assetJson("/farming.config").wetToDryMods
	seedDrop = config.getParameter("dropSeed")
	if type(seedDrop) ~= "string" then
		dontDropItem = seedDrop == false
		seedDrop = nil
	end
	if #stages > 0 then
		storage.stage = storage.stage or 1
		setImage()
		dontConsumeSoilMoisture = config.getParameter("consumeSoilMoisture") == false
	else
		storage.stage = nil
		sb.logWarn("No farmable stages found for " .. object.name())
	end
end

function resolveStageDuration(dur)
	if type(dur)=="table" then
		return math.max(table.unpack(dur))
	else
		return dur
	end
end

function update(dt)
	storage.groundPositions = storage.groundPositions or getGroundPositions()
	if storage.lastHarvest then
		if storage.stage and not storage.harvestable then
			local harvestMath=(world.time() - storage.lastHarvest)
			if (harvestMath<0) or (harvestMath>(resolveStageDuration(stages[storage.stage].duration))*100) then
				storage.harvestTime=util.randomInRange(stages[storage.stage].duration)+world.time()
			elseif harvestMath >= storage.harvestTime then
				if checkForMoisture(true) then
					grow()
				end
			end
		end
	else
		resetGrowthTime()
	end
end

function die()
	if storage.harvestable then
		dropHarvest()
		storage.stage = stages[storage.stage].resetToStage
		if storage.stage and not dontDropItem then
			world.spawnItem(seedDrop or object.name(), object.position())
		end
	elseif not dontDropItem then
		world.spawnItem(seedDrop or object.name(), object.position())
	end
end

function onInteraction()
	if storage.harvestable then
		storage.harvestable = false
		object.setInteractive(false)
		dropHarvest()
		storage.stage = stages[storage.stage].resetToStage
		if not storage.stage then
			dontDropItem = true
			object.smash(true)
			return
		else
			storage.stage = storage.stage + 1
		end
		resetGrowthTime()
		setImage()
	end
end

function grow()
	storage.stage = storage.stage + 1
	if storage.stage >= #stages then
		setImage()
		object.setInteractive(true)
		storage.harvestable = true
	else
		resetGrowthTime()
		setImage()
	end
end

function dropHarvest()
	if stages[storage.stage].harvestPool and root.isTreasurePool(stages[storage.stage].harvestPool) then
		for _, item in pairs (root.createTreasure(stages[storage.stage].harvestPool, world.threatLevel())) do
			world.spawnItem(item, object.position())
		end
	end
	if stages[storage.stage].spawnMonster then
		local monster = stages[storage.stage].spawnMonster
		local monsterPoly = root.monsterMovementSettings(monster).standingPoly
		local spawnPosition = findCompanionSpawnPosition(object.position(), monsterPoly)
		world.spawnMonster(monster, spawnPosition, stages[storage.stage].monsterParameters)
	end
end

function resetGrowthTime()
	if storage.stage ~= #stages then
		if checkForMoisture(false) then
			storage.lastHarvest = world.time()
			storage.harvestTime = util.randomInRange(stages[storage.stage].duration)
		else
			storage.lastHarvest = nil
		end
	end
end

function setImage()
	animator.setGlobalTag("stage", storage.stage - 1)
	if stages[storage.stage].alts then
		if not storage.alt then									--Assumes that it has the same amount of alts everytime it has alts
			storage.alt = math.random(0, stages[storage.stage].alts - 1)
		end
		animator.setGlobalTag("alt", storage.alt)
	else
		animator.setGlobalTag("alt", 0)
	end
end

function getGroundPositions()
	local groundPosition = object.position()
	local objectId = entity.id()
	local groundPositions = {}
	local modifiers = {{-1, 0}, {1, 0}}
	while world.objectAt(groundPosition) == objectId do			--Assumes the crops can only be placed on the ground
		groundPosition = vec2.add(groundPosition, {0, -1})
	end
	for _, modifier in pairs (modifiers) do
		local position = vec2.add(groundPosition, {0, 1})
		while world.objectAt(position) == objectId do
			table.insert(groundPositions, vec2.add(position, {0, -1}))
			position = vec2.add(position, modifier)
		end
	end
	return groundPositions
end

function checkForMoisture(consume)
	if dontConsumeSoilMoisture then
		return true
	end
	local modData = {}
	local noMoisture = false
	for _, position in pairs (storage.groundPositions) do
		local newMod = farmingModConfig[world.mod(position, "foreground")]
		if newMod then
			table.insert(modData, {position = position, mod = newMod})
		else
			noMoisture = true
			break
		end
	end
	if noMoisture then
		return false
	end
	if consume then
		for _, data in pairs (modData) do
			world.placeMod(data.position, "foreground", data.mod)
		end
	end
	if #modData > 0 then
		return true
	end
end
