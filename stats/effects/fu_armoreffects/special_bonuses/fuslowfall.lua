function init()
	script.setUpdateDelta(10)
	self.controlParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function update(dt)
	if mcontroller.falling() then
		if self.controlParameters then
			mcontroller.controlParameters(self.controlParameters)
		end
		if self.maxFallSpeed then
			mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed))
		end
	end

	if (world.windLevel(mcontroller.position()) >= 70 ) then
		mcontroller.controlModifiers({
			speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.12,
			airJumpModifier = 1.12
		})
	elseif (world.windLevel(mcontroller.position()) >= 7 ) then
		mcontroller.controlModifiers({
			speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.15,
			airJumpModifier = 1.20
		})
	end
end

function uninit()

end
