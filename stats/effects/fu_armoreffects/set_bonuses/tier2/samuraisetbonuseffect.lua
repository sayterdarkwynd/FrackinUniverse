require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_samuraiset"

armorBonus={
	{stat = "katanaMastery", amount = 0.15},
	{stat = "dodgetechBonus", amount = 0.1},
	{stat = "defensetechBonus", amount = 0.1}
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