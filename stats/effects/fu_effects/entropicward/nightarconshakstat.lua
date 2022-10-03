function init()
	local rAmt=config.getParameter("resistanceAmount", 0)
	effect.addStatModifierGroup({
		{stat = "cosmicResistance", amount = rAmt},
		{stat = "radioactiveResistance", amount = rAmt},
		{stat = "shadowResistance", amount = rAmt},
		{stat = "poisonResistance", amount = rAmt},
		{stat = "iceResistance", amount = rAmt},
		{stat = "fireResistance", amount = rAmt},
		{stat = "electricResistance", amount = rAmt},
		--reduce effects of Madness
		{stat = "mentalProtection", amount = rAmt}
	})
end

function update(dt)

end

function uninit()

end
