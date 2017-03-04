function init()
 --Power
  self.critChanceup = config.getParameter("critChanceMultiplier", 0)
  effect.addStatModifierGroup({{stat = "critChance", baseMultiplier = self.critChanceup}})
end


function update(dt)
--world.sendEntityMessage(
--  playerId,
--  "setBar",
--  unique name of the bar you want to add,
--  percentage (from 0 to 1),
--  colour in {r , g, b, a}
--)
world.sendEntityMessage(
  activeItem.ownerEntityId(),
  "setBar",
  config.getParameter("itemName"),
  status.critChance/100,
  {0,255,128,255}
  )
end

function uninit()
world.sendEntityMessage(
  playerId,
  "removeBar",
  config.getParameter("itemName")
)
end
