function init()
  self.movementParameters = config.getParameter("movementParameters", {})
  effect.addStatModifierGroup({
  {stat = "waterImmunity", amount = 1},
  {stat = "lavaImmunity", amount = 1},
  {stat = "poisonStatusImmunity", amount = 1},
  {stat = "tarImmunity", amount = 1},
  })
end

function update(dt)
  mcontroller.controlParameters(self.movementParameters)
end

function uninit()
  
end
