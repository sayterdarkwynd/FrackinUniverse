setName="fu_hackerset"

weaponEffect={}
  
armorBonus={
    {stat = "energyRegenPercentageRate", baseMultiplier = 1.25},
    {stat = "gasImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end	
end