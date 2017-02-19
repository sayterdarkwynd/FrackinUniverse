--deprecated code!

--require "/scripts/unifiedGravMod.lua"


function init()
	--unifiedGravMod.init()
  --self.gravityModifier = 1.0
  --self.movementParams = mcontroller.baseParameters()
  --effect.addStatModifierGroup({{stat = "asteroidImmunity", amount = 1}})
  --setGravityMultiplier()
  script.setUpdateDelta(0)
end

--[[function setGravityMultiplier()
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  self.newGravityMultiplier = self.gravityModifier * oldGravityMultiplier
end]]--

function update(dt)
	--unifiedGravMod.update(dt)
  --mcontroller.controlParameters( { gravityMultiplier = self.newGravityMultiplier } )
end
