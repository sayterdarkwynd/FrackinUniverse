require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/unifiedGravMod.lua"
setName="fu_wretchelset"

weaponBonus={ }

armorBonus={
	{stat = "biooozeImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
			
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
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"shortsword","broadsword","whip","axe","hammer","spear","shortspear","dagger"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

function uninit()
	unifiedGravMod.uninit()
	setBonusUninit()
end