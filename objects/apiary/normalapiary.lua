local contents

function init(virtual)
	if virtual == true then return end
	-- slots 17, 18, 19 for queen, drones, frame
	apiary_init(17, 18, 19)
end
