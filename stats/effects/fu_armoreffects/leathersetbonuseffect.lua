setName="fu_leatherset"

weaponEffect={
    {stat = "critChance", baseMultiplier = 1.12},
    {stat = "powerMultiplier", baseMultiplier = 1.05}
  }
  
armorBonus={
      {stat = "maxEnergy", baseMultiplier = 1.05},
      {stat = "critChance", baseMultiplier = 1.03},
      {stat = "grit", baseMultiplier = 0.2}
}

armorBonus2={
      {stat = "maxEnergy", baseMultiplier = 1.0},
      {stat = "critChance", baseMultiplier = 1.03},
      {stat = "grit", baseMultiplier = 0.1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	handler=effect.addStatModifierGroup({})
        daggerCheck()

    if (world.type() == "garden") or (world.type() == "forest")  then
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

	  mcontroller.controlModifiers({
	      speedModifier = 1.05
	    })
end

function daggerCheck()
	if weaponCheck("both",{"bow"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end