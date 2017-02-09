function init()
	self.params = mcontroller.baseParameters()
	script.setUpdateDelta(5)
end

function update(dt)
	if self.params.collisionEnabled then
		if self.params.gravityEnabled then
			--mcontroller.addMomentum({0,world.gravity(entity.position())*dt*self.params.gravityMultiplier})
			self.newParams={gravityEnabled = false,airForce=0,flySpeed=0}
		end
		mcontroller.controlParameters(self.newParams)
	end
	if effect.duration() < (effect.getParameter("defaultDuration",5)-0.1) then effect.expire() end
end
