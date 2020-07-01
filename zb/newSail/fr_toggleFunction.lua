function FR_toggleEffects()
	local fr_enabled = status.statusProperty("fr_enabled")

	if fr_enabled then
		text = "^cyan;Disabled FR species-specific effects.^reset;\n\nYou have ^yellow;no inherent bonuses or penalties^reset;, including dietary."
	else
		text = "^cyan;Restored FR species-specific effects.^reset;\n\nYour biological traits give you many ^green;strengths^reset;, but also inherent ^red;weaknesses^reset;."
	end
	status.setStatusProperty("fr_enabled", not fr_enabled)

	resetGUI()
	textTyper.init(cfg.TextData, text)
end