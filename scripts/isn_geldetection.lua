local oldUpdate = update

local isn_gelTable = {
  isn_accelgel = true,
  isn_bouncegel = true,
  isn_lowfrictionstrip = true,
  isn_propulsionstrip_l = true,
  isn_propulsionstrip_r = true
}

function update(dt)
	oldUpdate(dt)
	local gelPos = { mcontroller.xPosition(), math.floor(mcontroller.yPosition()-3)}
	local modCheck = world.mod(gelPos,"foreground")
	if isn_gelTable[modCheck] then
		status.addEphemeralEffect(modCheck)
	end
end

