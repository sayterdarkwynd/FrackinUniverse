require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.setParentDirectives("fade=404040=0.5")
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = 0.6,
		speedModifier = 0.65,
		airJumpModifier = 0.65
	})
end

function uninit()
	filterModifiers({},true)
end
