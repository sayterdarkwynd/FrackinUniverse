require "/scripts/util.lua"
require "/scripts/pathutil.lua"

function init()
	self = config.getParameter("spawner")
	self.timer = self.spawnTime
end

function update(dt)
	local slot = 0
	local fuelSlot = getInputContents(slot)
	self.timer = self.timer - dt
	if fuelSlot == self.fuelType then
		slot = 1
		podSlot = getInputContents(slot)
		if podSlot == self.podType then
			if self.timer <= 0 then
				world.containerConsumeAt(entity.id(),0,1)
				local items = world.containerItems(entity.id(), 1)
				for _,item in pairs(items) do
					pets = (item.parameters.pets)
					if pets then
						for _,pet in pairs(pets) do
						monsterType = pet.config.type
						monsterSeed = pet.config.parameters.seed
						monsterColour = pet.config.parameters.colors
						monsterAggro = pet.config.parameters.aggresive
						dropPool = {}
						dropPool["default"] = "empty"
						spawnPosition = vec2.add(object.position(), {0, 8})
						--if world.threatLevel() < 5 then
							--monsterLevel = 5
						--else
							monsterLevel = world.threatLevel()
						--end
							if monsterType and monsterSeed then
								if monsterColour then
									world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, colors = monsterColour, aggresive = monsterAggro, dropPools = dropPool});
								else
									world.spawnMonster(monsterType, spawnPosition, {level = monsterLevel, seed = monsterSeed, aggresive = monsterAggro, dropPools = dropPool});
								end
							end
						end
					end
				end
				self.timer = self.spawnTime
			end
		end
	end
end

function getInputContents(slot)
	local stack = world.containerItemAt(entity.id(),slot)
	local contents = {}
	if stack then
		contents = stack.name
	end
	return contents
end