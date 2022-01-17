require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_nomadset"

armorBonus={
	{stat="fireStatusImmunity",amount=1},
	{stat="quicksandImmunity",amount=1},
	{stat="sandstormImmunity",amount=1},
	{stat="shieldStaminaRegen",baseMultiplier=1.2}
}

weaponBonus1={
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
}

weaponBonus2={
	{stat="powerMultiplier",effectiveMultiplier=1.08 }
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
	local weapons2=weaponCheck({ "dagger", "knife", "shortspear" })
	local weapons1=weaponCheck({"assaultrifle", "sniperrifle"})
	if weapons1["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus2)
	elseif weapons2["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end