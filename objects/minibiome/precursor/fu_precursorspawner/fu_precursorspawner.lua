require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require '/scripts/power.lua'
local requiredPower = 0

function init()
	power.init()
	self = config.getParameter("spawner")
	self.timer = self.defaultSpawnTime
	powered = false
end

function update(dt)
	if wireCheck() == true then
		if not crafting then
			local slot = 0
			local fuelSlot = getInputContents(slot)
			if fuelSlot.name == self.fuelType then
				local slot = 1
				local podSlot = getInputContents(slot)
				if podSlot.name == self.podType then
					if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
						world.containerConsumeAt(entity.id(),0,1)
						pets = (podSlot.parameters.pets)
						pet = root.monsterParameters(pets[1].config.type)
						spawnTime = pet.statusSettings.stats.maxHealth.baseValue * self.spawnTimeMultiplier
						self.timer = spawnTime or self.defaultSpawnTime
						requiredPower = config.getParameter('isn_requiredPower')
						crafting = true
					end
				end
			end
		end
	end
	self.timer = self.timer - dt
	if crafting then
		if animator.animationState == "off" then
			animator.playSound("on")
			soundTimer = 1.131
		else
			if not soundTimer or soundTimer <= 0 then
				animator.playSound("running", -1)
			else
				soundTimer = soundTimer - dt
			end
		end
		animator.setAnimationState("base", "on")
	else
		if animator.animationState("base") == "on" then
			animator.stopAllSounds("running")
			animator.playSound("off")
		end
		animator.setAnimationState("base", "off")
	end
	if self.timer <= 0 and crafting then
		if power.consume(requiredPower) then
			if pets then
				monsterType = pets[1].config.type
				monsterSeed = pets[1].config.parameters.seed
				monsterColour = pets[1].config.parameters.colors
				monsterAggro = pets[1].config.parameters.aggressive
				blacklisted = checkBlacklist(monsterType)
				dropPool = {}
				dropPool["default"] = "empty"
				spawnPosition = vec2.add(object.position(), {0, 5})
				monsterLevel = math.max(5, world.threatLevel())
				if monsterType and monsterSeed then
					if blacklisted == true then
						world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, dropPools = dropPool, aggressive = monsterAggro, capturable = false, relocatable = false});
					else
						world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, aggressive = monsterAggro, capturable = false, relocatable = false});
					end
				end
			end
			crafting = false
		end
	end
	power.update(dt)
end

function getInputContents(slot)
	local stack = world.containerItemAt(entity.id(),slot)
	local contents = {}
	if stack then
		contents = stack
	end
	return contents
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
	if object.isInputNodeConnected(0) == true then
		if object.getInputNodeLevel(0) == true then
			return true
		else
			return false
		end
	else
	return true
	end
	return false
end