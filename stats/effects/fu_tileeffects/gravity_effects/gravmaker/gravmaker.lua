require "/scripts/unifiedGravMod.lua"

function init()
	unifiedGravMod.initSoft()
	unifiedGravMod.init()
  --self.gravityModifier = config.getParameter("gravityModifier")
  --self.movementParams = mcontroller.baseParameters()
  effect.addStatModifierGroup({
    {stat = "asteroidImmunity", amount = 1}
  })
  --setGravityMultiplier()
  --activateVisualEffects()

  script.setUpdateDelta(5)
end

--[[
function setGravityMultiplier()
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  self.newGravityMultiplier = self.gravityModifier * oldGravityMultiplier
end
]]--

--[[function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end]]--

function update(dt)
	unifiedGravMod.update(dt)
  --mcontroller.controlParameters( { gravityMultiplier = self.newGravityMultiplier } )
end
