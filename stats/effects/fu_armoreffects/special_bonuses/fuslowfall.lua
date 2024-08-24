require "/stats/effects/fu_statusUtil.lua"

function init()
	script.setUpdateDelta(10)
	self.controlParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function update(dt)
	if mcontroller.falling() then
		if self.controlParameters then
			mcontroller.controlParameters(self.controlParameters)
		end
		if self.maxFallSpeed then
			mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed))
		end
	end

	local speedValue=1.0
	local airJumpValue=1.0
	if (world.windLevel(mcontroller.position()) >= 70 ) then
		speedValue = 1.12
		airJumpValue = 1.12
	elseif (world.windLevel(mcontroller.position()) >= 7 ) then
		speedValue = 1.15
		airJumpValue = 1.2
	end
	applyFilteredModifiers({speedModifier=speedValue,airJumpModifier=airJumpValue})
end

function uninit()
	filterModifiers({},true)
end
