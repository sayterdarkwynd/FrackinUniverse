require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_underworldset"

weaponBonus={
	{stat="critChance",amount=1 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "pistol", "machinepistol" })
	local weapons2=weaponCheck({ "assaultrifle", "sniperrifle" })
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus,2.5))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	elseif weapons2["either"] and weapons2["twoHanded"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus,2))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
