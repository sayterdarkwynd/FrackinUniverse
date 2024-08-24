require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_warriorrobesset"

armorBonus={
	{stat = "foodDelta", baseMultiplier = 0.8},
	{stat = "critChance", amount = 0.5},
	{stat = "shadowImmunity", amount = 1},
	{stat = "insanityImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		applyFilteredModifiers({
			speedModifier = 1.08,
			airJumpModifier = 1.08
		})
	end
end
