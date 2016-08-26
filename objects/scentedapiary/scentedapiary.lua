local contents

function init(args)
	-- slots 17, 18, 19 for queen, drones, frame
	if apiary_init(17, 18, 19) then
		-- override defaults
		self.spawnDelay = 1.05
		self.spawnBeeBrake = nil -- none spawned
		self.spawnItemBrake = 150
		self.spawnHoneyBrake = 350
		self.spawnDroneBrake = 250
		self.beeStingChance = 0.5
	end
end
