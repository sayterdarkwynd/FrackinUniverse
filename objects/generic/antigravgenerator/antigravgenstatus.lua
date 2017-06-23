function init()
	self.params = mcontroller.baseParameters()
	script.setUpdateDelta(5)
end

function update(dt)
	
		if self.params.gravityEnabled then
			--mcontroller.addMomentum({0,world.gravity(entity.position())*dt*self.params.gravityMultiplier})
			self.newParams={
			  gravityEnabled = false,
			  airForce=5,
			  flySpeed=1.5,
			  airFriction=0
			  }
		end
	mcontroller.controlParameters(self.newParams)

end
