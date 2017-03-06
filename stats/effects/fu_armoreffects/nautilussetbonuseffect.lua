setName="fu_nautilusset"

armorBonus2={
      {stat = "critBonus", amount = 10},
      {stat = "powerMultiplier", baseMultiplier = 1.15},
      {stat = "sulphuricacidImmunity", amount = 1},
      {stat = "poisonStatusImmunity", amount = 1},
      {stat = "maxBreath", amount = 900},
      {stat = "breathRegeneration", baseMultiplier = 1.5}
}

armorBonus={
      {stat = "sulphuricacidImmunity", amount = 1},
      {stat = "poisonStatusImmunity", amount = 1},
      {stat = "maxBreath", amount = 900},
      {stat = "breathRegeneration", baseMultiplier = 1.5}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
    if (world.type() == "ocean") or (world.type() == "sulphuricocean") or (world.type() == "aethersea") or (world.type() == "nitrogensea") or (world.type() == "strangesea") or (world.type() == "tidewater") then
       effect.setStatModifierGroup(armorHandle,armorBonus2)	
    end
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
	if (world.type() == "ocean") or (world.type() == "sulphuricocean") or (world.type() == "aethersea") or (world.type() == "nitrogensea") or (world.type() == "strangesea") or (world.type() == "tidewater") then
		effect.setStatModifierGroup(armorHandle,armorBonus2)
		mcontroller.controlModifiers({
			speedModifier = 1.05
		})		
	else
		effect.setStatModifierGroup(armorHandle,armorBonus)
    end
end