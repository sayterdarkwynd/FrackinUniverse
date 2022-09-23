require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_shadowboneset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.30}
}

armorBonus={{stat="shadowImmunity",amount=1}}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
		mcontroller.controlModifiers({
			speedModifier = 1.10
		})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"axe","greataxe","hammer","scythe"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
