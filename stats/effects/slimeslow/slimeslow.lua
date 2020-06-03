function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=347857=0.8")
end

function update(dt)

	if world.entitySpecies(entity.id()) == "slimeperson" then
	self.healingRate = 0.025
	status.modifyResourcePercentage("health", self.healingRate * dt)
		  mcontroller.controlModifiers({
		      groundMovementModifier = 0.9,
		      speedModifier = 0.9,
		      airJumpModifier = 1.4
		    })
        else
		  mcontroller.controlModifiers({
		        groundMovementModifier = 0.5,
      			speedModifier = 0.25
		    })        
	end    
    
    
end

function uninit()

end
