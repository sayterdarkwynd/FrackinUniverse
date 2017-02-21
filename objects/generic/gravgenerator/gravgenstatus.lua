function init()
	params=mcontroller.baseParameters()
	effect.addStatModifierGroup({{stat = "asteroidImmunity", amount = 1}})
	self.movementParams = mcontroller.baseParameters()
	script.setUpdateDelta(5)
end

function update(dt)
	if params.collisionEnabled then
		--local magic=-102.4*dt
		local magic=-102.4*dt
		if params.gravityEnabled then
			mcontroller.addMomentum({0,magic})
		else
			mcontroller.addMomentum({0,magic*0.2})
		end
	end
	if effect.duration() < (effect.getParameter("defaultDuration",5)-0.3) then effect.expire() end
end
