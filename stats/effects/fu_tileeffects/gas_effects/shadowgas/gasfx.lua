function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(5)
  
  
  self.liquidMovementParameter = {
    groundForce = 70,
    airForce = 20,
    airFriction = 0.3,
    liquidForce = 50,
    liquidFriction = 0.35,
    liquidImpedance = 0.1,
    liquidBuoyancy = 0.25,
    minimumLiquidPercentage = 0.1,
    liquidJumpProfile = {
      jumpSpeed = 70.0,
      jumpControlForce = 610.0,
      jumpInitialPercentage = 0.45,
      jumpHoldTime = 0.2,
      multiJump = false,
      reJumpDelay = 1.05,
      autoJump = false,
      collisionCancelled = false 
    }
  }  
end

  

function update(dt)
mcontroller.controlParameters(self.liquidMovementParameter)

end

function uninit()

end