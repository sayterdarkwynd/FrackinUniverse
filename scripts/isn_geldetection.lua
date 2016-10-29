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
	
	for _, value in ipairs({ "isn_accelgel", "isn_bouncegel", "isn_lowfrictionstrip",
	"isn_propulsionstrip_l", "isn_propulsionstrip_r" }) do
	  if geltype == value then return true end
	end
	
	return false
end
