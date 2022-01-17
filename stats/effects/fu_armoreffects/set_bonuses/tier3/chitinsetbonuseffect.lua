require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_chitinset"

armorBonus2={
	{stat = "maxHealth", effectiveMultiplier = 1.12},
	{stat = "powerMultiplier", effectiveMultiplier = 1.12}
}

armorBonus={
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})

	checkWorld()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWorld()
	end
end

function checkWorld()
	if checkBiome({"sulphuric", "sulphuricdark", "sulphuricocean"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end