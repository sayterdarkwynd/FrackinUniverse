setName="fu_operativeset"

weaponEffect={}
  
armorBonus={
    {stat = "critChance", amount = 10},
    {stat = "critBonus", amount = 20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end	
end
