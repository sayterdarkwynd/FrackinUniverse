require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_hazmatset"

armorBonus={
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radioactiveResistance", amount = 0.5}
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
