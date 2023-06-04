function init()
  effect.setParentDirectives("fade=cc3aef=0.5")

  local slows = status.statusProperty("slows", {})
  slows["leoslow"] = 0.45
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.4,
      runModifier = 0.45,
      jumpModifier = 0.45
    })
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["leoslow"] = nil
  status.setStatusProperty("slows", slows)
end