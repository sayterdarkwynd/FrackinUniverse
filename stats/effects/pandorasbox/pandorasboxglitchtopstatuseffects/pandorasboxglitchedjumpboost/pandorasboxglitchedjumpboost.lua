require "/stats/effects/fu_statusUtil.lua"

function update(dt)
	applyFilteredModifiers({
		airJumpModifier = 1.5
	})
end

function uninit()
	filterModifiers({},true)
end
