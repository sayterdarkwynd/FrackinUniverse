function init()
	-- Heal percent is the configParameter in the json statuseffects file
	vfx=config.getParameter("displayVFX",true)
	flat = config.getParameter("flat")--value is per second if this is true
	self.regen = config.getParameter("energyrestore", 0)
	if not flat then
		self.regen=self.regen / effect.duration()
	end
	script.setUpdateDelta(5)
end


function update(dt)
	if status.isResource("energy") then
		status.modifyResourcePercentage("energy", self.regen * dt)
		--sb.logInfo("energyrestorepercentage.lua effect value per tick: %s",self.regen*dt)
		if vfx then
			effect.setParentDirectives("fade=005500="..0.4)
		end
	end
end
