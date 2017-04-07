function init()
  script.setUpdateDelta(5)
  self.healingRate = 1.0 / config.getParameter("energyTime", 10)
end

function update(dt)
  status.modifyResourcePercentage("energy", self.healingRate * dt)
end

function uninit()
  
end
