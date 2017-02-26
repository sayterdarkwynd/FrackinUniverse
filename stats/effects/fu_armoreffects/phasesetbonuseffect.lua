setName="fu_phaseset"

armorBonus={
	{stat ="electricResistance", amount = 0.4},
	{stat ="electricStatusImmunity" , amount = 1 },
	{stat ="pressureProtection" , amount = 1 },
	{stat ="extremepressureProtection" , amount = 1 }
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({
			speedModifier = 1.10,
			airJumpModifier = 1.10
		})
		status.modifyResourcePercentage("health", 0.006 * dt)--0.6% hp regen per second
	end
end