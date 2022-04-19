require "/scripts/vec2.lua"
function init()

  script.setUpdateDelta(5)
end

function isDry()
local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	if not world.liquidAt(mouthPosition) then
            status.clearPersistentEffects("lavahealing")
	    inWater = 0
	end
end

function update(dt)
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	local liquidId = mcontroller.liquidId()
	if (world.liquidAt(mouthPosition)) and (inWater == 0) and (liquidId== 2) or (liquidId== 8)then
            status.setPersistentEffects("lavahealing", {
              {stat = "physicalResistance", baseMultiplier = 1.25},
              {stat = "maxEnergy", baseMultiplier = 1.25},
              {stat = "maxHealth", baseMultiplier = 1.25}
            })
	    inWater = 1
	else
	  isDry()
        end
end

function uninit()

end
