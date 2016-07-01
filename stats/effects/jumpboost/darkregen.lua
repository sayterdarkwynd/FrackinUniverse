function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("jumpparticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
end

function update(dt)
	if lightLevel < 70 then
		local darkModifier = 1.0 - lightLevel -- The darker, the stronger
		local timer = 10
		--skillGain = self.minSkillDelta * darkModifier / ( self.darkWalkerSkillLevel + 1 )
		--self.darkWalkerSkill = self.darkWalkerSkill + skillGain
		
		if self.timer >= 1 then
			status.modifyResource( "health", 1 * self.darkModifier * maxHealth * dt )
		end
	else
		self.timer = 0.0
	end
end

function uninit()
  
end





