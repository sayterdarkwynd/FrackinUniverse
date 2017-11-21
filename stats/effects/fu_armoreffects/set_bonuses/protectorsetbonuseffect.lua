setName="fu_protectorset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorBonus={}

armorEffect={}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
        armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	weaponBonusHandle=effect.addStatModifierGroup({})
	armorBonusHandle=effect.addStatModifierGroup({})
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
	  effect.setStatModifierGroup(armorBonusHandle,armorBonus)
	else
	  effect.setStatModifierGroup(armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "shortsword","broadsword", "longsword", "katana", "dagger", "knife", "axe", "greataxe", "chakram", "rapier", "scythe" })
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end