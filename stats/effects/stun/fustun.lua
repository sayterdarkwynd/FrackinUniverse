require "/stats/effects/fu_statusUtil.lua"
local strong

function init()
	strong=config.getParameter("strong")
	effect.setParentDirectives("fade=7733AA=0.25")
end

function update(dt)
	applyFilteredModifiers({
		ToolUsageSuppressed = strong,
		facingSuppressed = strong,
		movementSuppressed = strong,
		groundMovementModifier = 0.5*((strong and 0.5) or 1),
		speedModifier = 0.5*((strong and 0.5) or 1.0),
		airJumpModifier = 0.7*((strong and 0.5) or 1.0)
	})
end

function uninit()
	filterModifiers({},true)
end
