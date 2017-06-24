function init()
  effect.addStatModifierGroup({ {stat = "asteroidImmunity", amount = 1} })
  self.liquidMovementParameter = {
    gravityEnabled = true,
    gravity = 90,
    gravityMultiplier = 1.2,
    airForce = 20.0,
    airFriction = 0.0,
    bounceFactor = 0.0,
    groundForce = 100.0,
    normalGroundFriction = 12.0,
    ambulatingGroundFriction = 0.8,
    collisionEnabled = true,
    frictionEnabled = true
  } 	
  script.setUpdateDelta(5)
end

function update(dt)
	    if mcontroller.zeroG() then
		mcontroller.setYVelocity(math.min(-4,mcontroller.yVelocity() - 1));
		mcontroller.controlParameters(self.liquidMovementParameter)
	    end	
end

function uninit()
  status.removeEphemeralEffect("gravgenfieldarmor")
  status.removeEphemeralEffect("gravgenfieldarmor2")
end