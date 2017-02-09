function init()
	params=mcontroller.baseParameters()
	effect.addStatModifierGroup({{stat = "asteroidImmunity", amount = 1}})
	self.movementParams = mcontroller.baseParameters()
	script.setUpdateDelta(5)
end

function update(dt)
	if params.collisionEnabled then
		if params.gravityEnabled then
			mcontroller.addMomentum({0,-102.4*dt})
		else
			mcontroller.addMomentum({0,-102.4*dt*0.2})
		end
	end
	if effect.duration() < (effect.getParameter("defaultDuration",5)-0.1) then effect.expire() end
end
