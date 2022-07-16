function init()
  effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.15},
    {stat = "wetImmunity", amount = 1},
    {stat = "maxBreath", amount = 1000}
  })
  self.movementParameters = config.getParameter("movementParameters", {})
end

function update(dt)
end

function uninit()
end
