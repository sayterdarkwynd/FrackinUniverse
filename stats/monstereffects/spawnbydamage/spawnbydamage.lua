--TODO add position offsetting,

function init()

	self.spawnCount 		= config.getParameter('spawnCount',1) + 1
	self.spawns 			= self.spawnCount
	self.spawnMonster 		= config.getParameter('spawnMonster')

end

function update(dt)

	if status.resourcePercentage('health') + 1 / self.spawnCount <  1 / self.spawnCount * self.spawns then
		world.spawnMonster(self.spawnMonster,mcontroller.position(),{aggressive = true})
		self.spawns = self.spawns - 1
	end

end

function uninit()
end
