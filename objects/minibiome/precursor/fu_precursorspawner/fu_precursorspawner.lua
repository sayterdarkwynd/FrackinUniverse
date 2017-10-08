require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require '/scripts/power.lua'
local crafting = false
local requiredPower = 0

function init()
	power.init()
	self = config.getParameter("spawner")
	self.timer = self.spawnTime
	powered = false
end

function update(dt)
	if wireCheck() == true then
		if crafting == false then
			local slot = 0
			local fuelSlot = getInputContents(slot)
			if fuelSlot == self.fuelType then
				slot = 1
				podSlot = getInputContents(slot)
				if podSlot == self.podType then
					if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
						--if power.getTotalEnergy() >= config.getParameter('isn_requiredPowerOverclocked') then
							--world.containerConsumeAt(entity.id(),0,1)
							--self.timer = self.spawnTime/2
							--animator.setAnimationState("base", "overclocked")
							--requiredPower = config.getParameter('isn_requiredPowerOverclocked')
							--crafting = true
						--else
							world.containerConsumeAt(entity.id(),0,1)
							self.timer = self.spawnTime
							animator.setAnimationState("base", "on")
							requiredPower = config.getParameter('isn_requiredPower')
							crafting = true
						--end
					end
				end
			end
		end
	end
	self.timer = self.timer - dt
	if self.timer <= 0 then
		if crafting == true then
			if power.consume(requiredPower) then
				local items = world.containerItems(entity.id(), 1)
				for _,item in pairs(items) do
					pets = (item.parameters.pets)
					if pets then
						for _,pet in pairs(pets) do
						monsterType = pet.config.type
						monsterSeed = pet.config.parameters.seed
						monsterColour = pet.config.parameters.colors
						monsterAggro = pet.config.parameters.aggressive
						blacklisted = checkBlacklist(monsterType)
						dropPool = {}
						dropPool["default"] = "empty"
						spawnPosition = vec2.add(object.position(), {0, 8})
						if world.threatLevel() < 5 then
							monsterLevel = 5
						else
							monsterLevel = world.threatLevel()
						end
							if monsterType and monsterSeed then
								if blacklisted == true then
									if monsterColour then
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, dropPools = dropPool, aggressive = monsterAggro, capturable = false, relocatable = false});
									else
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, dropPools = dropPool, aggressive = monsterAggro, capturable = false, relocatable = false});
									end
								else
									if monsterColour then
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, aggressive = monsterAggro, capturable = false, relocatable = false});
									else
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, aggressive = monsterAggro, capturable = false, relocatable = false});
									end
								end
							end
						end
					end
				end
			end
			crafting = false
		end
	end
	if not crafting and self.timer <= 0 then
		self.timer = self.spawnTime
		animator.setAnimationState("base", "off")
	end
	power.update(dt)
end

function getInputContents(slot)
	local stack = world.containerItemAt(entity.id(),slot)
	local contents = {}
	if stack then
		contents = stack.name
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