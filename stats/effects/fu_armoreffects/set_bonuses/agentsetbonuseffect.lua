setName="fu_agentset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorBonus={}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
	end
	mcontroller.controlModifiers({
		speedModifier = 1.25,
		airJumpModifier = 1.25
	})
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","pistol"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end