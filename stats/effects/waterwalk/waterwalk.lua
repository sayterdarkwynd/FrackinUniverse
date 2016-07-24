function init()
  local bounds = mcontroller.boundBox()
  self.liquidMovementParameter = {
	liquidBuoyancy = 3.2,
	liquidFriction = 0,
	runSpeed = 18,
	minimumLiquidPercentage = 0.2,
	liquidForce = 100
  }
  self.groundMovementParameter = {
	minimumLiquidPercentage = 0.2
  }  
   script.setUpdateDelta(5)
end


-- world.liquidAt( entity.position() )

function update(dt)

local inLiquid = mcontroller.liquidPercentage() > 0.01
    if inLiquid then
      mcontroller.controlParameters(self.liquidMovementParameter)
    else
      mcontroller.controlParameters(self.groundMovementParameter)
    end
end

function uninit()
  
end