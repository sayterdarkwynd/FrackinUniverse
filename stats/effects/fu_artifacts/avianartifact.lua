function init()
  script.setUpdateDelta(10)
end

function update(dt)
	if not mcontroller.onGround() then
	    status.setPersistentEffects("flightpower", {
	      {stat = "powerMultiplier", baseMultiplier = 1.10}
	    }) 
	else
	    status.clearPersistentEffects("flightpower")
	end
end

function uninit()

end