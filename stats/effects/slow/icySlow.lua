require "/stats/effects/fu_statusUtil.lua"

function init()
	if (status.stat("iceResistance")>=config.getParameter("resistanceThreshold",0.75)) then
		effect.expire()
		return
	end
	effect.setParentDirectives("fade=404040=0.5")

	didInit=true
end

function update(dt)
	if not didInit then return end
	applyFilteredModifiers({
		groundMovementModifier = 0.6,
		speedModifier = 0.65,
		airJumpModifier = 0.65
	})
end

function uninit()
	filterModifiers({},true)
end
