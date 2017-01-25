function init()
  script.setUpdateDelta(5)
end

function update(dt)
  self.healingRate = 0.004
  status.modifyResourcePercentage("health", self.healingRate * 10)
end

function uninit()
  
end