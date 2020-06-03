require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  local bounds = mcontroller.boundBox()
  self.healingRate = 1.01 / config.getParameter("healTime", 180)
  script.setUpdateDelta(5)
end


function update(dt)
    if status.resource("energy") >= status.stat("maxEnergy")/2 then
      	   self.healingRate = 1.0009 / config.getParameter("healTime", 180)
	   status.modifyResourcePercentage("health", self.healingRate * dt)  
    end  

end

function uninit()

end







