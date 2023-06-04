require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/unifiedGravMod.lua"
setName="fu_wretchelset"

armorBonus={
	{stat = "biooozeImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)

	unifiedGravMod.init()
	unifiedGravMod.initSoft()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		unifiedGravMod.update(dt)

		checkWeapons()
	end
end

function uninit()
	unifiedGravMod.uninit()
	setBonusUninit()
end