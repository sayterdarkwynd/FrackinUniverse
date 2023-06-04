
function init()
	effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
	self.fallingParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function update()
	if mcontroller.falling() then
		mcontroller.controlParameters(self.fallingParameters or {})
		mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed or 0))
	end
	mcontroller.controlModifiers({
		airJumpModifier = 1.45,
		jumpHoldTime = 1.0
	})
end

function unit()

end
