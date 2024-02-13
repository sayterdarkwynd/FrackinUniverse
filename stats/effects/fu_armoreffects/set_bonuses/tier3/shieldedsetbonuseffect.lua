require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_shieldedset"

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.15})
	end
end
