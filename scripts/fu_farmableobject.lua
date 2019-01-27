require "/scripts/util.lua"
require "/scripts/vec2.lua"

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
		if not storage.lastHarvest then
			resetGrowthTime()
		end
		setImage()
		dontConsumeSoilMoisture = config.getParameter("consumeSoilMoisture") == false
	else
		storage.stage = nil
		sb.logWarn("No farmable stages found for " .. object.name())
	end
end

function update(dt)
	if storage.stage and not storage.harvestable then
		if world.time() - storage.lastHarvest >= storage.harvestTime then
			if dontConsumeSoilMoisture then
				grow()
			else
				if checkForMoisture() then
					grow()
				end
			end
		end
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
end

function resetGrowthTime()
	if storage.stage ~= #stages then
		storage.lastHarvest = world.time()
		storage.harvestTime = util.randomInRange(stages[storage.stage].duration)
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

function checkForMoisture()
	local groundPosition = object.position()
	local objectId = entity.id()
	local noMoisture = false
	local modData = {}
	local modifiers = {{-1, 0}, {1, 0}}
	while world.objectAt(groundPosition) == objectId do			--Assumes the crops can only be placed on the ground
		groundPosition = vec2.add(groundPosition, {0, -1})
	end
	for _, modifier in pairs (modifiers) do
		local position = vec2.add(groundPosition, {0, 1})
		while world.objectAt(position) == objectId do
			local modPosition = vec2.add(position, {0, -1})
			local newMod = farmingModConfig[world.mod(modPosition, "foreground")]
			if newMod then
				table.insert(modData, {position = modPosition, mod = newMod})
				position = vec2.add(position, modifier)
			else
				noMoisture = true
				break
			end
		end
		if noMoisture then
			break
		end
	end
	if noMoisture then
		return false
	end
	for _, data in pairs (modData) do
		world.placeMod(data.position, "foreground", data.mod)
	end
	if #modData > 0 then
		return true
	end
end