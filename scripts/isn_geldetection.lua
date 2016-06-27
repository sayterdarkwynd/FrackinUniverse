local oldUpdate = update

function update(dt)
	oldUpdate(dt)
	local gelPos = { mcontroller.xPosition(), math.floor(mcontroller.yPosition()-3)}
	local modCheck = world.mod(gelPos,"foreground")
	if isn_getGelStatus(modCheck) == true then
		status.addEphemeralEffect(modCheck)
	end
end

function isn_getGelStatus(geltype)
	local validTypes = { "isn_accelgel", "isn_bouncegel", "isn_lowfrictionstrip",
	"isn_propulsionstrip_l", "isn_propulsionstrip_r" }
	
	for key, value in pairs(validTypes) do
		if geltype == value then return true end
	end
	
	return false
end