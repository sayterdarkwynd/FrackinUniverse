function init()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", "amount": 0.1},
    {stat = "fallDamageMultiplier", effectiveMultiplier = 0.5}
  })
  
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
