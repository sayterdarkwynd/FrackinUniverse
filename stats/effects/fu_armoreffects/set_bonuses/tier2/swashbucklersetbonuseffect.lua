require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_swashbucklerset"

armorBonus={
	{stat="rapierMastery",amount=0.15 },
	{stat="foodDelta",baseMultiplier=0.8 }
}

weaponBonus1={
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
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
		mcontroller.controlModifiers({jump=1.8})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "rapier", "pistol" })
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,0.5))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end