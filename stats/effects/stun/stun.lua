require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.setParentDirectives("fade=7733AA=0.25")
end

function update(dt)
	applyFilteredModifiers({
		ToolUsageSuppressed = true,
		facingSuppressed = true,
		movementSuppressed = true,
		groundMovementModifier = 0.5,
		speedModifier = 0.5,
		airJumpModifier = 0.7
	})
end

function uninit()
	filterModifiers({},true)
end
