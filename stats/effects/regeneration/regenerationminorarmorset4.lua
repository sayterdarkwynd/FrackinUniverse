function init()
  script.setUpdateDelta(5)
end

function update(dt)
  self.healingRate = 0.00002
  status.modifyResourcePercentage("health", self.healingRate * 1.0)
end

function uninit()
  
end