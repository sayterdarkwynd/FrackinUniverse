function init()
  script.setUpdateDelta(10)
  handler=effect.addStatModifierGroup({})
end

function update(dt)
  if not mcontroller.onGround() then
    effect.setStatModifierGroup(handler, {{stat = "powerMultiplier", effectiveMultiplier = 1.15}})
  else
    effect.setStatModifierGroup(handler,{})
  end
end

function uninit()
  effect.removeStatModifierGroup(handler)
end