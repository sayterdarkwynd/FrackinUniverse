function init()
  effect.addStatModifierGroup({ {stat = "asteroidImmunity", amount = 1} })
  self.liquidMovementParameter = {
    gravityEnabled = true,
    gravityMultiplier = 1.5,
    airForce = 20.0,
    airFriction = 0.0,
    bounceFactor = 0.0
  } 	
  script.setUpdateDelta(5)
end

function update(dt)
	    if not mcontroller.onGround() or mcontroller.zeroG() then
		mcontroller.setYVelocity(math.min(-2,mcontroller.yVelocity() - 1));
		mcontroller.controlParameters(self.liquidMovementParameter)
	    end	
end