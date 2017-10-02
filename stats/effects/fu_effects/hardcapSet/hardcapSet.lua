require "/scripts/vec2.lua"

function init()
self.baseHealth = status.stat("maxHealth")-status.stat("maxHealth")
self.baseEnergy = status.stat("maxEnergy")
self.basePower = status.stat("powerMultiplier")
self.baseProtection = status.stat("protection")
self.baseCrit = status.stat("critChance")
self.baseCritBonus = status.stat("critBonus")
self.baseShieldBash = status.stat("shieldBash")

    if status.stat("maxHealth") >= 120 then
	  effect.addStatModifierGroup({
	      {stat = "maxHealth", amount = 0 },
	      {stat = "maxHealth", amount = 1 }
	  })
	  sb.logInfo("maxHealth reduced to Hard-Cap of 100")
    end
    if status.stat("maxEnergy") >= 500 then
	  effect.addStatModifierGroup({
	      {stat = "maxEnergy", amount = 0  }
	  })
	  sb.logInfo("maxEnergy reduced to Hard-Cap of XXX")
    end
    if status.stat("powerMultiplier") >= 8.5 then
	  effect.addStatModifierGroup({
	      {stat = "powerMultiplier", amount = 0  }
	  })
	  sb.logInfo("powerMultiplier reduced to Hard-Cap of XXX")
    end
    if status.stat("protection") >= 150 then
	  effect.addStatModifierGroup({
	      {stat = "protection", amount = 0  }
	  })
	  sb.logInfo("protection reduced to Hard-Cap of XXX")
    end
    if status.stat("critChance") >= 35 then
	  effect.addStatModifierGroup({
	      {stat = "critChance", amount = 0  }
	  })
	  sb.logInfo("critChance reduced to Hard-Cap of XXX")
    end
    if status.stat("critBonus") >= 50 then
	  effect.addStatModifierGroup({
	      {stat = "critBonus", amount = 0  }
	  })
	  sb.logInfo("critBonus reduced to Hard-Cap of XXX")
    end
    if status.stat("shieldBash") >= 45 then
	  effect.addStatModifierGroup({
	      {stat = "shieldBash", amount = 0  }
	  })
	  sb.logInfo("shieldBash reduced to Hard-Cap of XXX")
    end
   
end


function update(dt)

     
end


function uninit()

end