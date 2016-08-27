local contents

function init(virtual)
	if virtual == true then return end
	-- slots 17, 18, 19 for queen, drones, frame
	if apiary_init(17, 18, 19) then
		self.beeStingChance = 0.5
	end
end
