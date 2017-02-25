setName="fu_underworldset"

weaponEffect={
    {stat = "critChance", baseMultiplier = 1.12}
  }
  
armorBonus={
    {stat = "electricResistance", baseMultiplier = 1.15},
    {stat = "iceResistance", baseMultiplier = 1.15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	handler=effect.addStatModifierGroup({})
        daggerCheck()
	effect.addStatModifierGroup(armorBonus)	
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end	
end

function daggerCheck()
	if weaponCheck("both",{"rifle","pistol","machinepistol"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end