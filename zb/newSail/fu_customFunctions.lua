function fu_toggleAtmosphereMode()
	local text = ""
	if player.worldId() ~= player.ownShipWorldId() then
		text = "Only the owner of the ship can switch the atmosphere mode."
	elseif world.getProperty("ship.level") ~= 0 then
		text = "This feature is BYOS only."
	elseif world.getProperty("fu_byos.newAtmosphereSystem") then
		world.setProperty("fu_byos.newAtmosphereSystem", false)
		text = "BYOS atmosphere mode has been set to only check for background behind the player."
	else
		world.setProperty("fu_byos.newAtmosphereSystem", true)
		text = "BYOS atmosphere mode has been set to check if the player is in an enclosed room (WIP)."
	end
	resetGUI()
	textTyper.init(cfg.TextData, text)
end