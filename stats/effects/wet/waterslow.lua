function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	effect.setParentDirectives("fade=0072ff=0.1")
	script.setUpdateDelta(5)
end

function update(dt)
	if world.entitySpecies(entity.id()) ~= "hylotl" then
		mcontroller.controlModifiers({
			runModifier = 1.3,
			jumpModifier = 1.3
		})
	elseif world.entitySpecies(entity.id()) == "floran" then
		mcontroller.controlModifiers({
			runModifier = 1.2,
			jumpModifier = 1.2
		})
	else
		mcontroller.controlModifiers({
			runModifier = 0.9,
			jumpModifier = 0.9
		})
	end 
end