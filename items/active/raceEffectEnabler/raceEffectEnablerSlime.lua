function activate(fireMode, shiftHeld)
    self.species = world.entitySpecies(activeItem.ownerEntityId())
    if fireMode == "primary" then
      if self.species == "slimeperson" then
        player.makeTechAvailable("colorvariableslimesphere")
        player.enableTech("colorvariableslimesphere")
        player.equipTech("colorvariableslimesphere") 	
        player.makeTechAvailable("stickywalljump")
        player.enableTech("stickywalljump")
        player.equipTech("stickywalljump") 	
      end
      animate()
    else
      animator.setParticleEmitterActive("butterflies", false)	
      animator.setParticleEmitterActive("butterflies2", false)
      animator.setParticleEmitterActive("butterflies3", false)
    end

end

function animate()
    	animator.setParticleEmitterOffsetRegion("butterflies", mcontroller.boundBox())
    	animator.setParticleEmitterActive("butterflies", true)	
    	animator.setParticleEmitterOffsetRegion("butterflies2", mcontroller.boundBox())
    	animator.setParticleEmitterActive("butterflies2", true)
    	animator.setParticleEmitterOffsetRegion("butterflies3", mcontroller.boundBox())
    	animator.setParticleEmitterActive("butterflies3", true)    	
    	animator.playSound("activate")
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end








