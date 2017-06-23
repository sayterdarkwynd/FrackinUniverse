function init()
  effect.addStatModifierGroup({
    {stat = "asteroidImmunity", amount = 1}
  })
   -- vanilla 0g settings	
   --[[ "flySpeed" : 1.5,
    "airForce" : 0.75,
    "airFriction" : 0,
    "bounceFactor" : 0.3]]--
    
  self.liquidMovementParameter = {
    gravityMultiplier = 1.5,
    airForce = 20.0,
    airFriction = 0.0,
    bounceFactor = 0.0
  } 	
	script.setUpdateDelta(5)
end

function update(dt)
	mcontroller.controlParameters(self.liquidMovementParameter)
end
