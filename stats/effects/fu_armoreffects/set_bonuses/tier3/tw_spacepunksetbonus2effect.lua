require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_tw_spacesuit2set"

armorBonus={
	{stat = "maxBreath", effectiveMultiplier = 30}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end