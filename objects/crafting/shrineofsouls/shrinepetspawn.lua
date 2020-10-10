require "/scripts/util.lua"

function init()
	self.shrineSpawnList=config.getParameter("shrineSpawnList")
	if (self.shrineSpawnList) and (type(self.shrineSpawnList)=="table") then
		self.shrineSpawnListSize=util.tableSize(self.shrineSpawnList)
	end
	self.shrineSpawnChance=config.getParameter("shrineSpawnChance",100)
	self.shrineSpawnInterval=config.getParameter("shrineSpawnInterval",120)
	if self.shrineSpawnListSize and (self.shrineSpawnListSize > 0) then
		script.setUpdateDelta(60)
	else
		script.setUpdateDelta(0)
	end
end

function update(dt)
	if not self.shrineSpawnList then return end
	self.timer=(self.timer or 0)+dt
	if self.timer>=self.shrineSpawnInterval then
		if self.shrineSpawnChance>=math.random(100) then
			local cheep=self.shrineSpawnList[math.random(self.shrineSpawnListSize)]
			world.spawnMonster(cheep,entity.position())
		end
		self.timer=0
	end
end