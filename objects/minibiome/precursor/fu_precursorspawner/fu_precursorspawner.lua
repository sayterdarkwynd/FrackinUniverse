require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require '/scripts/power.lua'
local requiredPower = 0

function init()
	power.init()
	self = config.getParameter("spawner")
	requiredPower = config.getParameter('isn_requiredPower')
	storage.timer = self.defaultSpawnTime
	if storage.crafting then
		animator.playSound("running", -1)
	end
	powered = false
end

function update(dt)
	if not storage.timer then
		self = config.getParameter("spawner")
		requiredPower = config.getParameter('isn_requiredPower')
		storage.timer = self.defaultSpawnTime
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
			if fuelSlot.name == self.fuelType then
				local podSlot = getInputContents(1)
				if podSlot.name == self.podType then
					if power.getTotalEnergy() >= requiredPower then
						world.containerConsumeAt(entity.id(),0,1)
						storage.pets = (podSlot.parameters.pets)
						pet = root.monsterParameters(storage.pets[1].config.type)
						spawnTime = pet.statusSettings.stats.maxHealth.baseValue * (self.spawnTimeMultiplier or 0.1)
						storage.timer = spawnTime or self.defaultSpawnTime
						
						storage.crafting = true
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
					local blacklisted = checkBlacklist(monsterType)
					
					params.seed = storage.pets[1].config.parameters.seed
					params.colors = storage.pets[1].config.parameters.colors
					params.aggressive = storage.pets[1].config.parameters.aggressive
					params.level = blacklisted and math.max(8, world.threatLevel()) or math.max(5, world.threatLevel())
					
					if blacklisted then
						params.dropPools = {}
						params.dropPools["default"] = "empty"
					end
					
					if monsterType and params.seed then
						world.spawnMonster(monsterType, spawnPosition, params);
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

function checkBlacklist(monster)
	blacklist = root.assetJson('/objects/minibiome/precursor/fu_precursorspawner/fu_precursorspawnerblacklist.config')
	for _,blacklistMonster in pairs (blacklist) do
		if monster == blacklistMonster then
			return true
		end
	end
	return false
end

function wireCheck()
	if object.isInputNodeConnected(0) then
		return object.getInputNodeLevel(0)
	else
		return true
	end
end