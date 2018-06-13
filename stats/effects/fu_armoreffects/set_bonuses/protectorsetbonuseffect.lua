setName="fu_protectorset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorBonus={}

armorEffect={}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
		status.removeEphemeralEffect( "damageheal" )
	else
		status.addEphemeralEffect( "damageheal" )
		checkWeapons()
		checkArmor()
	end
end

function checkArmor()
	if (world.type() == "garden") or (world.type() == "forest") then
	  effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
	  effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "shortsword","broadsword", "longsword", "katana", "dagger", "knife", "axe", "greataxe", "chakram", "rapier", "scythe" })
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end