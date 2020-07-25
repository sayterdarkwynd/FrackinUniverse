function init()
	effect.setParentDirectives("fade=FFCC00=0.20")
	baseValue = config.getParameter("defenseModifier",0)
	effect.addStatModifierGroup({{stat = "protection", effectiveMultiplier = baseValue }})
end

function update(dt) end

function uninit() end