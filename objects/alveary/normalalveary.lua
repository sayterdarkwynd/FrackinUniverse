local contents

function init(args)
	-- slots 37, 38, 39, 40 for queen, drones, frame
	if apiary_init(37, 38, 39, 40) then
		-- override defaults
		self.spawnDelay = 0.8
		self.spawnBeeBrake = 350
		self.spawnItemBrake = 150
		self.spawnHoneyBrake = 300
		self.spawnDroneBrake = 250
		self.limitDroneCount = false
		self.beeStingOffset = { 3, 2.5 }
	end
end
