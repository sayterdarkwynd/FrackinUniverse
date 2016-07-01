function init()
  effect.setParentDirectives("fade=cccccc=0.5")

  local slows = status.statusProperty("slows", {})
  slows["crystalmoonfx"] = 0.01
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = -0.0,
      runModifier = -0.0
    })
  mcontroller.controlParameters({
      normalGroundFriction = -0.4
    })
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["crystalmoonfx"] = nil
  status.setStatusProperty("slows", slows)
end