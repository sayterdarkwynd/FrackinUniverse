function init()
  effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.25},
    {stat = "wetImmunity", amount = 1},
    {stat = "maxBreath", amount = 1500}
  })
  self.movementParameters = config.getParameter("movementParameters", {})
end

function update()
end

function uninit()
end
