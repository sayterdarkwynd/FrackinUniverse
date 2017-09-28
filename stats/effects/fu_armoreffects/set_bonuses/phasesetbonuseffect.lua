setName="fu_phaseset"

armorBonus={
	{stat ="electricStatusImmunity" , amount = 1 },
	{stat ="pressureProtection" , amount = 1 },
	{stat ="extremepressureProtection" , amount = 1 },
	{stat ="critChance" , amount = 5 }
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({
			speedModifier = 1.20,
			airJumpModifier = 1.20
		})
		status.modifyResourcePercentage("health", 0.008 * dt)
	end
end