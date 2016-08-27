local contents

function init(virtual)
	if virtual == true then return end
	-- slots 37, 38, 39, 40 for queen, drones, frame
	if apiary_init(37, 38, 39, 40) then
		-- override defaults

		-- original, oddly high values, here for posterity in case they were needed for some strange reason -renbear
		-- -- basic spawn variance:
		-- self.spawnBeeBrake = 350
		-- self.spawnItemBrake = 150
		-- self.spawnHoneyBrake = 300
		-- self.spawnDroneBrake = 250

		self.limitDroneCount = false
		self.beeStingOffset = { 3, 2.5 }
		self.beePowerScaling = 2
	end
end
