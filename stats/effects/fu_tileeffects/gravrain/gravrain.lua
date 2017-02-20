--deprecated code
--[[function init()
  self.gravityModifier = config.getParameter("gravityModifier")
  self.movementParams = mcontroller.baseParameters()

  setGravityMultiplier()

  activateVisualEffects()
end

function setGravityMultiplier()
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1

  self.newGravityMultiplier = self.gravityModifier * oldGravityMultiplier
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)

  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")

end

function update(dt)
  mcontroller.controlParameters({
     gravityMultiplier = self.newGravityMultiplier
  })
end

function uninit()

end
]]--