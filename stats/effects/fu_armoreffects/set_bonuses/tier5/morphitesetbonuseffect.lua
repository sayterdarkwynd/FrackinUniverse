require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_morphiteset"

armorEffect={
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
