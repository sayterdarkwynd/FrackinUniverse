function fu_toggleAtmosphereMode()
	local text
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

function fu_configureShipPet()
	local shipPet = world.getObjectParameter(pane.sourceEntity(), "shipPetType")
	if not shipPet then
		text = "This feature only works on SAILs that have a pet."
		resetGUI()
		textTyper.init(cfg.TextData, text)
		return
	end

	local petConfigPane = root.assetJson("/interface/objectcrafting/fu_pethouse/fu_pethouse.config")
	if petConfigPane and petConfigPane.gui then
		petConfigPane.gui.itemGrid = nil
		petConfigPane.gui.changeObjectPet = nil
		petConfigPane.gui.addObjectPetToList = nil
		petConfigPane.containerId = pane.sourceEntity()
		player.interact("ScriptPane", petConfigPane)
	end
end

function fu_crashberry()
		status.clearAllPersistentEffects()
		status.clearEphemeralEffects()
end
