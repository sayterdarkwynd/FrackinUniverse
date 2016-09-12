function init()
  if status.stat("headcheck") == 1 and status.stat("chestcheck") == 1 and status.stat("legcheck") == 1 then
    -- So this is pretty straight forward we are checking for added stat values which are set by each part. If all parts are set then the character turns blue.
    --There is one important thing to note though, because this happens in init and not update. The order you put on clothes is important.
    --If you put helmet first then pants and chest you won't turn blue, because it is not constantly checking. If you put on helmet last you will turn blue. 
    effect.addStatModifierGroup({
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "extremepressureProtection", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "liquidnitrogenImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1}
    })
     
  script.setUpdateDelta(0)
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")
  else
    sb.logInfo("Not all parts detected")
  end
end

function update(dt)
  head = status.stat("headcheck")
  chest = status.stat("chestcheck")
  legs = status.stat("legcheck")
  sb.logInfo(head .. " Head")
  sb.logInfo(chest .. " Chest")
  sb.logInfo(legs .. " Legs")
end

function uninit()
end
