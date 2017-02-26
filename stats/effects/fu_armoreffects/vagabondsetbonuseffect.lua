setName="fu_vagabondset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
    {stat = "fireResistance", amount = 0.15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	daggerCheck()
	armorHandle=effect.addStatModifierGroup(armorBonus)	
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end	
end

function daggerCheck()
	if weaponCheck("both",{"pistol","machinepistol"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end