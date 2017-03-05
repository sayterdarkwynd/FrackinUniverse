function init()
 --Power
  self.critChanceup = config.getParameter("critChanceMultiplier", 0)
  effect.addStatModifierGroup({
    {stat = "critChance", baseMultiplier = self.critChanceup}
  })
end


function update(dt)
--world.sendEntityMessage(
--  playerId,
--  "setBar",
--  unique name of the bar you want to add,
--  percentage (from 0 to 1),
--  colour in {r , g, b, a}
--)
	if status.stat("critChance") then
		world.sendEntityMessage(
		  activeItem.ownerEntityId(),
		  "setBar",
		  "critEffector",
		  status.stat("critChance")/100,
		  {0,255,128,255}
		  )
	else
		status.setStatusProperty("critChance",0)
	end
end

function uninit()
world.sendEntityMessage(
  activeItem.ownerEntityId(),
  "removeBar",
  "critEffector"
)
end
