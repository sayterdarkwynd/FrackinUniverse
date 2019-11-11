require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "maxEnergy", effectiveMultiplier = 1.20},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonResistance", amount = 0.15},
	{stat = "physicalResistance", amount = 0.15},
	{stat = "xiBonus", baseMultiplier = 1.20}
}

armorEffect={}

setName="fu_chitinsetradien"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
	end
end

function checkArmor()
	if (world.type() == "sulphuric") or (world.type() == "sulphuricdark") or (world.type() == "sulphuricocean") then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end