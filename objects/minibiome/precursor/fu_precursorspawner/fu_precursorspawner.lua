require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require '/scripts/power.lua'
local crafting = false

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
					world.containerConsumeAt(entity.id(),0,1)
					self.timer = self.spawnTime
					if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then
						emp()
						powered = true
						animator.setAnimationState("base", "overclocked")
					else
						powered = false
						animator.setAnimationState("base", "on")
					end
					crafting = true
				end
			end
		end
	end
	self.timer = self.timer - dt
	if self.timer <= 0 then
		if crafting == true then
			local items = world.containerItems(entity.id(), 1)
			for _,item in pairs(items) do
				pets = (item.parameters.pets)
				if pets then
					for _,pet in pairs(pets) do
					monsterType = pet.config.type
					monsterSeed = pet.config.parameters.seed
					monsterColour = pet.config.parameters.colors
					monsterAggro = pet.config.parameters.aggressive
					dropPool = {}
					dropPool["default"] = "empty"
					spawnPosition = vec2.add(object.position(), {0, 8})
					if world.threatLevel() < 5 then
						monsterLevel = 5
					else
						monsterLevel = world.threatLevel()
					end
						if monsterType and monsterSeed then
							if powered == true then
								if power.consume(config.getParameter('isn_requiredPower')) then
									emp()
									if monsterColour then
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, aggressive = monsterAggro});
									else
										world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, aggressive = monsterAggro});
									end
								end
							else
								if monsterColour then
									world.spawnMonster(monsterType, spawnPosition, {level = world.threatLevel(), seed = monsterSeed, colors = monsterColour, dropPools = dropPool, aggressive = monsterAggro});
								else
									world.spawnMonster(monsterType, spawnPosition, {level = world.threatLevel(), seed = monsterSeed, dropPools = dropPool, aggressive = monsterAggro});
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

function emp()
	local objects = world.objectQuery(entity.position(), self.empRadius)
	for _,object in pairs (objects) do
		local isTurret = world.getObjectParameter(object, "maxEnergy")
		if isTurret then
			world.breakObject(object, false)
		end
	end
end