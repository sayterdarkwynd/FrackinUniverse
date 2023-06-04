function init()
	if (status.stat("iceResistance")>=config.getParameter("resistanceThreshold",0.75)) then
		effect.expire()
		return
	end
	effect.setParentDirectives("fade=404040=0.5")

	local slows = status.statusProperty("slows", {})
	slows["iceslow"] = 0.65
	status.setStatusProperty("slows", slows)
	didInit=true
end

function update(dt)
	if not didInit then return end
	mcontroller.controlModifiers({
		groundMovementModifier = 0.6,
		runModifier = 0.65,
		jumpModifier = 0.65
	})
end

function uninit()
	if didInit then
		local slows = status.statusProperty("slows", {})
		slows["iceslow"] = nil
		status.setStatusProperty("slows", slows)
	end
end