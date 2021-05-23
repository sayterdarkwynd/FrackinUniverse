function init()
	effect.addStatModifierGroup({{stat = "fallDamageMultiplier", effectiveMultiplier = 0.10}})
	--self.movementParams = mcontroller.baseParameters()
	self.liquidMovementParameter = {
		airJumpProfile = {
			jumpSpeed = 30
		}
	}
	script.setUpdateDelta(5)
	self.controlParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function update(dt)
	mcontroller.controlParameters(self.liquidMovementParameter)
	if mcontroller.falling() then
		if self.controlParameters then
			mcontroller.controlParameters(self.controlParameters)
		end
		if self.maxFallSpeed then
			mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed))
		end
	end
end

function uninit()

end


