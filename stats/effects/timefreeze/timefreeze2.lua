function init()
	if animator then
		animator.setParticleEmitterOffsetRegion("numerals", mcontroller.boundBox())
		animator.setParticleEmitterActive("numerals", true)
		effect.setParentDirectives("fade=e43774=0.4")
		animator.playSound("timefreeze_start")
		animator.playSound("timefreeze_loop", -1)
		animator.setAnimationRate(0)
	end
	effect.addStatModifierGroup({{stat="timeFreeze",amount=1}})
	if status.isResource("stunned") then
		status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
	end

	shield=config.getParameter("shield")
	if shield then
		if type(shield) == "table" then
			for _,v in pairs(shield) do
				status.addEphemeralEffect(v, effect.duration())
			end
		elseif type(shield) == "string" then
			status.addEphemeralEffect(shield, effect.duration())
		end
	end

	mcontroller.setVelocity({0, 0})
end

function update(dt)
	mcontroller.setVelocity({0, 0})
	mcontroller.controlModifiers({
		facingSuppressed = true,
		movementSuppressed = true
	})
	if status.isResource("stunned") then
		status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
	end
	if shield then
		if type(shield) == "table" then
			for _,v in pairs(shield) do
				status.addEphemeralEffect(v, effect.duration())
			end
		elseif type(shield) == "string" then
			status.addEphemeralEffect(shield, effect.duration())
		end
	end
end

function uninit()
	if animator then
		animator.setAnimationRate(1)
	end
end
