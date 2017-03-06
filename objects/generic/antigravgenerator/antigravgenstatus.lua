function init()
	self.params = mcontroller.baseParameters()
	script.setUpdateDelta(5)
end

function update(dt)
	if self.params.collisionEnabled then
		if self.params.gravityEnabled then
			--mcontroller.addMomentum({0,world.gravity(entity.position())*dt*self.params.gravityMultiplier})
			self.newParams={gravityEnabled = false,airForce=5,flySpeed=5,airFriction=3}
		end
		mcontroller.controlParameters(self.newParams)
	end
	local temp=(effect.duration()-math.floor(effect.duration()))
	if  temp < 2/3 and temp > 0 then effect.expire() end
end
