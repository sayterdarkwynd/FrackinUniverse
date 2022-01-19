require "/scripts/status.lua"
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_spacediverset"

weaponBonus2={
	{stat="powerMultiplier",effectiveMultiplier=1.2}
}

armorBonus={
	{stat="grit",amount=0.2},
	{stat="maxBreath",effectiveMultiplier=2},
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle2=effect.addStatModifierGroup({})
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
	local weaponSword=weaponCheck({"harpoon"})

	if weaponSword["both"] or weaponSword["twoHanded"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,{})
	end
end