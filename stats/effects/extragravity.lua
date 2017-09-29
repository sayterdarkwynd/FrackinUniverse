function init()
  self.movementParameters = config.getParameter("movementParameters", {})
  effect.addStatModifierGroup({
    {stat = "lavaImmunity", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "tarImmunity", amount = 1},
    {stat = "wetImmunity", amount = 1},
    {stat = "waterImmunity", amount = 1},
    {stat = "biooozeImmunity", amount = 1},
    {stat = "blacktarImmunity", amount = 1},
    {stat = "liquidnitrogenImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "pusImmunity", amount = 1}
  })
end

function update(dt)
  mcontroller.controlParameters(self.movementParameters)
end

function uninit()
  
end
