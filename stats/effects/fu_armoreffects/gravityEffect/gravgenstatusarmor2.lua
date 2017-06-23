function init()
  effect.addStatModifierGroup({ {stat = "asteroidImmunity", amount = 1} })
  self.liquidMovementParameter = {
    gravityEnabled = true,
    gravity = 90,
    gravityMultiplier = 1.5,
    airForce = 20.0,
    airFriction = 0.0,
    bounceFactor = 0.0,
    groundForce = 100.0,
    normalGroundFriction = 14.0,
    ambulatingGroundFriction = 1.0,
    collisionEnabled = true,
    frictionEnabled = true 
  } 	
  script.setUpdateDelta(5)
end

function update(dt)
	    if mcontroller.zeroG() then
		--mcontroller.setYVelocity(math.min(-2,mcontroller.yVelocity() - 1));
		mcontroller.addMomentum({0, -1*dt})
		mcontroller.controlParameters(self.liquidMovementParameter)
            else
                mcontroller.controlParameters(self.liquidMovementParameter)
	    end	
end

