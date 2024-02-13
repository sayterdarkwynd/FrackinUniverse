require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_corruptset"

armorBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "maxHealth", effectiveMultiplier = 1.25}
}

armorEffect={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("scouteyecultistblast")
		effect.expire()
	else
		status.addEphemeralEffect("scouteyecultistblast")
		checkArmor()
	end
end

function checkArmor()
	if checkBiome({"astral","aethersea","lightless","moon_shadow","shadow","midnight"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end
