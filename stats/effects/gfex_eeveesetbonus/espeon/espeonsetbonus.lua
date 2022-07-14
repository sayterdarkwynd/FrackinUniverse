function init()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 0.15},
    {stat = "fallDamageMultiplier", effectiveMultiplier = 0.7}
  })
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
