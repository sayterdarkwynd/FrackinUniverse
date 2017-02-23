function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(5)
end

function update(dt)
  mcontroller.controlModifiers({
      speedModifier = 1.10,
      airJumpModifier = 1.10
    })
  self.healingRate = 0.0005
  status.modifyResourcePercentage("health", self.healingRate * 1.0)
end

function uninit()
  
end