function init()
	--[[effect.addStatModifierGroup({
		{stat = "foodDelta", baseMultiplier = config.getParameter("regenAmount", 0.09)}
	})]]
	--self.regenAmount= config.getParameter("regenAmount")
	--self.timerbase = config.getParameter("timer")
	--self.timer = config.getParameter("timer")
	script.setUpdateDelta(10)
	shipOnly=config.getParameter("shipOnly")
	groundOnly=config.getParameter("groundOnly")
	if status.isResource("food") then
		animator.setParticleEmitterOffsetRegion("feed", mcontroller.boundBox())
		animator.setParticleEmitterActive("feed", config.getParameter("particles", true))
	end

end

function update(dt)
	if (shipOnly and not world.getProperty("ship.fuel")) or (groundOnly and world.getProperty("ship.fuel")) then
		effect.expire()
	end
	--[[
	if status.isResource("food") then
		if self.timer == 0 then
			status.modifyResource("food", self.regenAmount)
			self.timer = self.timerbase
		end
		self.timer = self.timer - dt
	end
	]]
end

function uninit()
	--sb.logInfo("uninit")
	--effect.expire()
end