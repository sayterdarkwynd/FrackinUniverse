require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.setParentDirectives("fade=cc3aef=0.5")
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = 0.4,
		speedModifier = 0.45,
		airJumpModifier = 0.45
	})
end

function uninit()
	filterModifiers({},true)
end
