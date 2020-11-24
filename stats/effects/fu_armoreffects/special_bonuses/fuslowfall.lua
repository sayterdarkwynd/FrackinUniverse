function init()
  script.setUpdateDelta(10)
end

function update(dt)
	if mcontroller.falling() then
	  mcontroller.controlParameters(config.getParameter("fallingParameters"))
	  mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), config.getParameter("maxFallSpeed")))
	end

	if (world.windLevel(mcontroller.position()) >= 70 ) then
		mcontroller.controlModifiers({
		  speedModifier = 1.12,
		  airJumpModifier = 1.12
		})
	elseif (world.windLevel(mcontroller.position()) >= 7 ) then
		mcontroller.controlModifiers({
		  speedModifier = 1.15,
		  airJumpModifier = 1.20
		})
	end
end

function uninit()

end