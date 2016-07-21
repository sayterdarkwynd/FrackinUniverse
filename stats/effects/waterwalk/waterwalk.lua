function init()
  local bounds = mcontroller.boundBox()
  self.liquidMovementParameter = {
	liquidBuoyancy = 3
  }
end

function update(dt)
mcontroller.controlParameters(self.liquidMovementParameter)
   
end

function uninit()
  
end