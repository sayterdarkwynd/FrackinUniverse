require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	stages = config.getParameter("stages")
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
		if storage.stage then
			world.spawnItem(object.name(), object.position())
		end
	elseif not dontDropItem then
		world.spawnItem(object.name(), object.position())
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
		animator.setGlobalTag("alt", math.random(0, stages[storage.stage].alts - 1))
	else
		animator.setGlobalTag("alt", 0)
	end
end

function checkForMoisture()
	local groundPosition = object.position()
	local objectId = entity.id()
	local modPositions = {}
	local noMoisture = false
	local modifiers = {{-1, 0}, {1, 0}}
	while world.objectAt(groundPosition) == objectId do			--Assumes the crops can only be placed on the ground
		groundPosition = vec2.add(groundPosition, {0, -1})
	end
	for _, modifier in pairs (modifiers) do
		local position = vec2.add(groundPosition, {0, 1})
		while world.objectAt(position) == objectId do
			local modPosition = vec2.add(position, {0, -1})
			if world.mod(modPosition, "foreground") == "tilled" then
				table.insert(modPositions, modPosition)
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
	sb.logInfo(sb.printJson(modPositions))
	for _, position in pairs (modPositions) do
		world.placeMod(position, "foreground", "tilleddry")
	end
	if #modPositions > 0 then
		return true
	end
end