setName="fu_nautilusset"

armorBonus2={
		{stat = "critChance", amount = 3},
		{stat = "powerMultiplier", amount = 0.15},
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "gasImmunity", amount = 1},
		{stat = "poisonStatusImmunity", amount = 1},
		{stat = "maxBreath", amount = 700},
		{stat = "breathRegeneration", baseMultiplier = 1.5}
}

armorBonus={
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "gasImmunity", amount = 1},
		{stat = "poisonStatusImmunity", amount = 1},
		{stat = "maxBreath", amount = 700},
		{stat = "breathRegeneration", baseMultiplier = 1.5}
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
		status.removeEphemeralEffect("swimboost1")
		effect.expire()
        else
        	status.addEphemeralEffect("swimboost1")
	end

	if (world.type() == "ocean") or (world.type() == "sulphuricocean") or (world.type() == "aethersea") or (world.type() == "nitrogensea") or (world.type() == "strangesea") or (world.type() == "tidewater") then
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus2)
		mcontroller.controlModifiers({
			speedModifier = 1.05
		})	
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	end
end