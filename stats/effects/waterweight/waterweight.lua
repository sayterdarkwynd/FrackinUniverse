require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.setParentDirectives("fade=D1CC87=0.1")
end

function update(dt)
	applyFilteredModifiers({
		speedModifier = 0.7,
		airJumpModifier = 0.55
	})
end

function uninit()
	filterModifiers({},true)
end
