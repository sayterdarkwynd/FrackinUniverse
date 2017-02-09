require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  local heldItem = world.entityHandItem(entity.id(), "primary")
  local heldItem2 = world.entityHandItem(entity.id(), "alt")
  
    if heldItem or heldItem2  then
	      if root.itemHasTag(heldItem, "energy") or root.itemHasTag(heldItem, "assaultrifle") then
		  setBonusInit("fu_intersecset", {
	    {stat = "critChance", amount = 5},
	    {stat = "physicalResistance", amount = 0.05},
	    {stat = "poisonResistance", amount = 0.15},
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "biomeradiationImmunity", amount = 1},
            {stat = "slimestickImmunity", amount = 1},
            {stat = "slimefrictionImmunity", amount = 1},
            {stat = "protoImmunity", amount = 1}
		  })
	      end
       else
	  setBonusInit("fu_intersecset", {
	    {stat = "physicalResistance", amount = 0.05},
	    {stat = "poisonResistance", amount = 0.15},
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "biomeradiationImmunity", amount = 1},
            {stat = "slimestickImmunity", amount = 1},
            {stat = "slimefrictionImmunity", amount = 1},
            {stat = "protoImmunity", amount = 1}
	  })      
    end  	
end