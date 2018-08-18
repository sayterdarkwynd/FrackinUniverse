function init()
	script.setUpdateDelta(5)

	animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
	animator.setParticleEmitterActive("coldbreath", true)

	--config --
	decreasePower = config.getParameter("decreasePower",0)
	biomeTimer = 10
	effect.setParentDirectives("fade=ffea00=0.027")
	baseValue = config.getParameter("biomeDmgPerTick")
	activateVisualEffects()
end


function activateVisualEffects()
	effect.setParentDirectives("fade=306630=0.8")
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
end


function makeAlert()
	world.spawnProjectile(
		"teslaboltsmall",
		mcontroller.position(),
		entity.id(),
		directionTo,
		false,
		{
			power = 0,
			damageTeam = sourceDamageTeam
		}
	)
	animator.playSound("bolt")
end



function update(dt)
	biomeTimer = biomeTimer - dt
	if biomeTimer <= 0 and status.stat("powerMultiplier") >= 1 then
		effect.addStatModifierGroup({{stat = "powerMultiplier", amount = baseValue* (-1) }})
		biomeTimer = 20
		makeAlert()
		activateVisualEffects()
	end
end

function uninit()

end