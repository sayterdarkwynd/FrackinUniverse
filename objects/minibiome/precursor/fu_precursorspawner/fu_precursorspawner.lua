require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require '/scripts/fupower.lua'
local requiredPower = 0

function init()
	power.init()
	spawner = config.getParameter("spawner")
	requiredPower = config.getParameter('isn_requiredPower')
	storage.timer = spawner.defaultSpawnTime
	if storage.crafting then
		animator.playSound("running", -1)
	end
	powered = false
end

function update(dt)
	if not storage.timer then
		spawner = config.getParameter("spawner")
		requiredPower = config.getParameter('isn_requiredPower')
		storage.timer = spawner.defaultSpawnTime
	elseif type(storage.timer) ~= "number" then
		storage.timer=tonumber(storage.timer)
	end
	if storage.timer >= 0 then
		storage.timer = storage.timer - dt
	else
		storage.timer=-1
	end

	if wireCheck() then
		if not storage.crafting then
			local fuelSlot = getInputContents(0)
			if fuelSlot.name == spawner.fuelType then
				local podSlot = getInputContents(1)
				if podSlot.name == spawner.podType then
					if power.getTotalEnergy() >= requiredPower then
						storage.pets = (podSlot.parameters.pets)
						pet = root.monsterParameters(storage.pets[1].config.type)
						fuelAmount = pet.statusSettings.stats.maxHealth.baseValue * (spawner.fuelMultiplier or 0.1)
						storage.fuelAmount = fuelAmount or spawner.defaultFuelAmount
						if world.containerConsumeAt(entity.id(),0,storage.fuelAmount) then
							spawnTime = pet.statusSettings.stats.maxHealth.baseValue * (spawner.spawnTimeMultiplier or 0.1)
							storage.timer = spawnTime or spawner.defaultSpawnTime
							storage.crafting = true
						end
					end
				end
			end
		end
	end

	if storage.crafting then
		if animator.animationState("base") == "off" then
			animator.playSound("on")
			soundTimer = 1.131
		else
			if soundTimer and soundTimer <= 0 then
				animator.playSound("running", -1)
				soundTimer = nil
			elseif soundTimer then
				soundTimer = soundTimer - dt
			end
		end
		animator.setAnimationState("base", "on")

		if storage.timer <= 0  then
			if power.consume(requiredPower) then
				if storage.pets then
					local params={}
					local spawnPosition = vec2.add(object.position(), {0, 5})

					local monsterType = storage.pets[1].config.type
					local baseParams = root.monsterParameters(monsterType)

					params.seed = storage.pets[1].config.parameters.seed
					params.colors = storage.pets[1].config.parameters.colors
					params.aggressive = storage.pets[1].config.parameters.aggressive
					params.level = world.threatLevel()

					params.dropPools = {}
					params.dropPools["default"] = "fu_precursorspawnerloot"

					params.statusSettings = baseParams.statusSettings or {}
					params.statusSettings.stats = baseParams.statusSettings.stats or {}
					params.statusSettings.stats.boozeImmunity = {baseValue = 1.0}
					params.statusSettings.statusProperties = params.statusSettings.stats.statusProperties or {}
					params.statusSettings.statusProperties.fu_precursorSpawned = true

					params.anchorName = object.name() --to make ship pets spawned by it not despawn

					params.behaviorConfig = util.mergeTable(baseParams.behaviorConfig or {}, params.behaviorConfig or {})

					if baseParams.deathBehavior and baseParams.deathBehavior ~= "monster-death" then --Makes it so that this doesn't break some monsters (maybe make them just drop the beer item instead?)
					else
						params.deathBehavior = "monster-death"
						params.behaviorConfig.deathActions = params.behaviorConfig.deathActions or {}
						table.insert(params.behaviorConfig.deathActions, {name = "action-projectile", parameters = {aimDirection={0,-1},projectileType = "fu_beer", projectileParameters = {actionOnReap = {{action = "liquid", liquid = "beer", quantity = storage.fuelAmount }}}}})
					end

					for actionType, actions in pairs (params.behaviorConfig) do
						if type(actions) == "table" then
							local tempActions = actions
							for num, action in pairs (actions) do
								if type(action) == "table" then
									if action.name == "action-spawnmonster" then
										tempActions[num] = false
									elseif action.name == "action-spawncompanions" then
										tempActions[num] = false
									end
								end
							end
							params.behaviorConfig[actionType] = {}
							for _, action in pairs (tempActions) do
								if action then
									table.insert(params.behaviorConfig[actionType], action)
								end
							end
						end
					end

					if monsterType and params.seed then
						local monsterId = world.spawnMonster(monsterType, spawnPosition, params);
						world.callScriptedEntity(monsterId, "setAnchor", entity.id())	--to allow ship pets to be spawned
					end
				end
				storage.crafting = false
			end
		end
	else
		if animator.animationState("base") == "on" then
			animator.stopAllSounds("running")
			animator.playSound("off")
		end
		animator.setAnimationState("base", "off")
	end
	power.update(dt)
end

function getInputContents(slot)
	return world.containerItemAt(entity.id(),slot) or {}
end

function wireCheck()
	if object.isInputNodeConnected(0) then
		return object.getInputNodeLevel(0)
	else
		return true
	end
end