require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  local heldItem = world.entityHandItem(entity.id(), "primary")
  local heldItem2 = world.entityHandItem(entity.id(), "alt")
  
    if heldItem or heldItem2  then
	      if root.itemHasTag(heldItem, "axe") or root.itemHasTag(heldItem, "hammer") then
		  setBonusInit("fu_bearset", {
		    {stat = "iceResistance", amount = 0.15},
		    {stat = "coldimmunity", amount = 1},
		    {stat = "critChance", amount = 25}
		  })
	      end
       else
	  setBonusInit("fu_bearset", {
	    {stat = "iceResistance", amount = 0.15},
	    {stat = "coldimmunity", amount = 1}
	  })      
    end  	
end