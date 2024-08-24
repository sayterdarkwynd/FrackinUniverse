require "/stats/effects/fu_statusUtil.lua"

function init()
	effect.setParentDirectives("fade=ffea00=0.4")
	self.energyCost = 2
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = 0.6,
		speedModifier = 0.65,
		airJumpModifier = 0.80
	})
end

function uninit()
	filterModifiers({},true)
end
