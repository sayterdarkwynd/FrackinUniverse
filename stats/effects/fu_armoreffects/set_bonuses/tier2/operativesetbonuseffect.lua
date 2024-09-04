require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_operativeset"

armorBonus={
	{stat="critChance",amount=4 },
	{stat="critDamage",amount=0.2 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		applyFilteredModifiers({speedModifier=1.08,airJumpModifier=1.08})
	end
end
