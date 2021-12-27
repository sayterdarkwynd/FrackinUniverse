function init()
	script.setUpdateDelta(5)
	self.liquidMovementParameter = {
		airForce = 35,
		liquidBuoyancy = 0.725,
		airJumpProfile = {
			jumpSpeed = 36.0
		}
	}
end


function update(dt)
	mcontroller.controlParameters(self.liquidMovementParameter)
end

function uninit()

end