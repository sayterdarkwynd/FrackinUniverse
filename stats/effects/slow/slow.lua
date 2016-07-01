function init()
  effect.setParentDirectives("fade=404040=0.5")

  local slows = status.statusProperty("slows", {})
  slows["leoslow"] = 0.65
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.6,
      runModifier = 0.65,
      jumpModifier = 0.65
    })
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["leoslow"] = nil
  status.setStatusProperty("slows", slows)
end