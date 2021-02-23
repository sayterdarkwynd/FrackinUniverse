require "/scripts/util.lua"

function init()
	self = config.getParameter("spawner")
	if not self then
		sb.logInfo("Monster spawner at %s is missing configuration! Prepare for some serious Lua errors!", object.position())
		return
	end

	object.setInteractive(self.trigger == "interact")
	self.position = object.toAbsolutePosition(self.position)
	storage.cooldown = storage.cooldown or util.randomInRange(self.frequency or {0, 0})
	storage.stock = storage.stock or self.stock

	self.monsterParams = self.monsterParams or {}
	self.monsterParams.uniqueId = config.getParameter("monsterUniqueId")
	local ePos=entity.position()
	self.dungeonIDList={}
	for xP=math.floor(ePos[1])-100,math.ceil(ePos[1])+100 do--math.floor(math.min(blockLine[1][1],blockLine[2][1])),math.ceil(math.max(blockLine[1][1],blockLine[2][1])) do
		for yP=math.floor(ePos[2])-10,math.ceil(ePos[2])+1 do--math.floor(math.min(blockLine[1][2],blockLine[2][2])),math.ceil(math.max(blockLine[1][2],blockLine[2][2])) do
			self.dungeonIDList[world.dungeonId({xP,yP})]=world.isTileProtected({xP,yP})
		end
	end
	world.setTileProtection(0,true)
	self.dungeonIDList[0]=nil
	for id,_ in pairs(self.dungeonIDList) do
		world.setTileProtection(id,true)
	end
end

function onInteraction(args)
	if self.trigger == "interact" then
		spawn()
	end
end

function update(dt)
	if storage.stock ~= 0 and not world.getProperty("fu_shoggothDied") and world.loadUniqueEntity(self.monsterParams.uniqueId) == 0 then
		if storage.cooldown > 0 then storage.cooldown = storage.cooldown - dt end

		if storage.cooldown <= 0 and ((not self.trigger) or (self.trigger == "wire" and object.getInputNodeLevel(0))) then
			spawn()
			storage.cooldown = util.randomInRange(self.frequency or {0, 0})
		end
	end
end

function die()
	if self.trigger == "break" then
		for i = 1, storage.stock do
			spawn()
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
			--sb.logInfo("fusspawner: level %s, wlevel %s",self.monsterLevel,world.threatLevel())

			local monsterId = world.spawnMonster(monsterType, spawnPosition, self.monsterParams or {})
			--sb.logInfo("fusspawner: spawning %s with params %s",monsterType,self.monsterParams)
			if monsterId ~= 0 then
				storage.stock = storage.stock - 1
				return
			end
		end

		attempts = attempts - 1
	end
end
