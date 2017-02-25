setName="fu_nomadset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.10}
  }
  
armorBonus={
	      {stat = "blacktarImmunity", baseMultiplier = 1},
	      {stat = "quicksandImmunity", baseMultiplier = 1},
	      {stat = "maxHealth", baseMultiplier = 1.15},
	      {stat = "maxEnergy", baseMultiplier = 1.10},
              {stat = "radiationburnImmunity", amount = 1},
              {stat = "sandstormImmunity", baseMultiplier = 1},
              {stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

armorBonus2={
	      {stat = "blacktarImmunity", baseMultiplier = 1},
	      {stat = "quicksandImmunity", baseMultiplier = 1},
	      {stat = "sandstormImmunity", baseMultiplier = 1},
              {stat = "radiationburnImmunity", amount = 1},
              {stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	handler=effect.addStatModifierGroup({})
        daggerCheck()
    if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then
       effect.addStatModifierGroup(armorBonus)	
    else
       effect.addStatModifierGroup(armorBonus2)	
    end  
    
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end
end

function daggerCheck()
	if weaponCheck("both",{"dagger"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end