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

	mcontroller.controlModifiers({
		speedModifier =  config.getParameter("speedBonus",0),
		airJumpModifier =  config.getParameter("jumpBonus",0)
	})
end

function uninit()

end