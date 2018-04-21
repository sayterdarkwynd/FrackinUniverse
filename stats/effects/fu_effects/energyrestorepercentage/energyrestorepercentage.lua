function init()
	-- Heal percent is the configParameter in the json statuseffects file
	vfx=config.getParameter("displayVFX",true)
	self.healingRate = config.getParameter("healPercent", 0) / effect.duration()
	script.setUpdateDelta(5)
end


function update(dt)
	if status.isResource("energy") then
		status.modifyResourcePercentage("energy", self.healingRate * dt)
		if vfx then
			effect.setParentDirectives("fade=005500="..0.4)
		end
	end
end
