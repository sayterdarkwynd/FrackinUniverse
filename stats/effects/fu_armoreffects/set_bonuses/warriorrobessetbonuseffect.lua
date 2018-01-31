setName="fu_warriorrobesset"

armorEffect={
	{stat = "shadowImmunity", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "critChance", amount = 0.5},
	{stat = "foodDelta", baseMultiplier = 0.8}
}


require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	mcontroller.controlModifiers({
	  airJumpModifier = 1.08,
	  speedModifier = 1.08
	})
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end