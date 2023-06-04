require "/scripts/util.lua"

function init()
	self = config.getParameter("spawner")
	if not self then
		sb.logInfo("Monster spawner at %s is missing configuration! Prepare for some serious Lua errors!", entity.position())
		return
	end

	object.setInteractive(self.trigger == "interact")
	self.position = object.toAbsolutePosition(self.position)
	storage.cooldown = storage.cooldown or util.randomInRange(config.getParameter("spawner.frequency"))
	storage.stock = storage.stock or self.stock
end

function onInteraction(args)
	if self.trigger == "interact" then
		spawn()
	end
end

function update(dt)
	if storage.stock ~= 0 then
		if storage.cooldown > 0 then storage.cooldown = storage.cooldown - dt end

		if storage.cooldown <= 0 and ((not self.trigger) or (self.trigger == "wire" and object.getInputNodeLevel(0))) then
			spawn()
			storage.cooldown = util.randomInRange(self.frequency)
		end
	end
end

function spawn()
	local attempts = 10
	while attempts > 0 do
		local spawnPosition = {}
		for i,val in ipairs(self.positionVariance) do
			if val == 0 then
				spawnPosition[i] = self.position[i]
			else
				spawnPosition[i] = self.position[i] + math.random(val) - (val / 2)
			end
		end

		if not self.outOfSight or not world.isVisibleToPlayer({spawnPosition[1] - 3, spawnPosition[2] - 3, spawnPosition[1] + 3, spawnPosition[2] + 3}) then
			local monsterType = util.randomFromList(self.monsterTypes)
			self.monsterParams.level = self.monsterLevel and util.randomInRange(self.monsterLevel) or (world.threatLevel()+(self.monsterLevelOffset or 0))
			--sb.logInfo("mwms: level %s, wlevel %s",self.monsterLevel,world.threatLevel())
			local monsterId = world.spawnMonster(monsterType, spawnPosition, self.monsterParams)
			--sb.logInfo("mwms: spawning %s with params %s",monsterType,self.monsterParams)
			if monsterId ~= 0 then
				storage.stock = storage.stock - 1
				return
			end
		end

		attempts = attempts - 1
	end
end
