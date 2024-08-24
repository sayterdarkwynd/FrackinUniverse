require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
end

function update(dt)
	if status.stat("iceResistance") < 70.0 then
		applyFilteredModifiers({
			groundMovementModifier = 0.75,
			speedModifier = 0.75,
			airJumpModifier = 0.8
		})
	else
		applyFilteredModifiers({
			groundMovementModifier = 1,
			speedModifier = 1,
			airJumpModifier = 1
		})
	end
end

function uninit()
	filterModifiers({},true)
end
