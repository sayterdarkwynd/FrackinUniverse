function init()

  script.setUpdateDelta(5)
end



function update(dt)
local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
local mouthful = world.liquidAt(mouthposition)
	if (world.liquidAt(mouthPosition)) and (inWater == 0) and (mcontroller.liquidId()== 2) or (mcontroller.liquidId()== 8)then
            status.setPersistentEffects("lavahealing", {
              {stat = "physicalResistance", baseMultiplier = 1.20},
              {stat = "perfectBlockLimit", amount = 2},
              {stat = "maxHealth", baseMuiltiplier = 1.25}
            })
	    inWater = 1
	else
	  isDry()
        end 
end

function uninit()
  status.clearPersistentEffects("lavahealing")
end