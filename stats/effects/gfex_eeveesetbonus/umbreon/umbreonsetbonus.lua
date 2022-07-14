function init()
  effect.addStatModifierGroup({{stat = "cosmicResistance", amount = 0.1}})
end

function update(dt)
  status.addEphemeralEffect("gfex_umbrethorns", 5)
end

function uninit()
end
