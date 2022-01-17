require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_wolfset"

armorBonus={
	{stat="daggerMastery",amount=0.15 },
	{stat="iceStatusImmunity",amount=1},
	{stat="snowslowImmunity",amount=1}
}

weaponBonus1={
	{stat="critDamage",amount=0.2 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons1=weaponCheck({"dagger", "shortsword","knife"})
	if weapons1["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	elseif weapons1["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,0.5))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end