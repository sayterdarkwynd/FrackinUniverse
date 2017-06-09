setName="fu_leviathanset"

armorBonus2={
		{stat = "critBonus", baseMultiplier = 1.08},
		{stat = "powerMultiplier", amount = 0.15},
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "poisonStatusImmunity", amount = 1},
		{stat = "biooozeImmunity", amount = 1},
		{stat = "breathProtection", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "swimboost3", amount = 1}
}

armorBonus={
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "gasImmunity", amount = 1},
		{stat = "poisonStatusImmunity", amount = 1},
		{stat = "biooozeImmunity", amount = 1},
		{stat = "breathProtection", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "swimboost3", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	if (world.type() == "ocean") or (world.type() == "sulphuricocean") or (world.type() == "aethersea") or (world.type() == "nitrogensea") or (world.type() == "strangesea") or (world.type() == "tidewater") then
		effect.setStatModifierGroup(armorBonusHandle,armorBonus2)
	end
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
end
if (world.type() == "ocean") or (world.type() == "sulphuricocean") or (world.type() == "aethersea") or (world.type() == "nitrogensea") or (world.type() == "strangesea") or (world.type() == "tidewater") then
	effect.setStatModifierGroup(armorBonusHandle,armorBonus2)

	mcontroller.controlModifiers({
		speedModifier = 1.05
	})
else
	effect.setStatModifierGroup(armorBonusHandle,armorBonus)
	end
end
