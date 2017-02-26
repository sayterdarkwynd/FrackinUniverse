function init()
  effect.addStatModifierGroup({
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "blacktarImmunity", amount = 1},
    {stat = "fumudslowImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "pusImmunity", amount = 1},
    {stat = "shadowResistance", amount = 0.20}
  })
end

function update(dt)
end

function uninit()
  
end