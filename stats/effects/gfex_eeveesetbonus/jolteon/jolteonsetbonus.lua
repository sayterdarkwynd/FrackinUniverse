function init()
  effect.addStatModifierGroup({{stat = "electricResistance", amount = 0.25}, {stat = "electricStatusImmunity", amount = 1}})

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
