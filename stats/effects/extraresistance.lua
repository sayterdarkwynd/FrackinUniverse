function init()
  status.setStatusProperty("hitInvulnerabilityTime", 3)
  effect.addStatModifierGroup({
    {stat = "grit", amount = 1 }
  })
  effect.addStatModifierGroup({
    {stat = "stunImmunity", amount = 1 }
  }) 
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 0.2}
  })
end

function update(dt)

end

function uninit()
    status.setStatusProperty("hitInvulnerabilityTime", 1)
end