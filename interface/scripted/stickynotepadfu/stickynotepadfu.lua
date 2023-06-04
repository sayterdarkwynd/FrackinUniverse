function init()
	self.sounds = config.getParameter("sounds")
	self.colors = config.getParameter("colors")

	self.write = 0
end

function update(dt)
	if not world.sendEntityMessage(player.id(), "holdingNotepad"):result() then
		pane.dismiss()
	end
	if self.write > 0 then
		self.write = self.write - 1
	end
end

function writeSound()
	if self.write == 0 then
		self.write = 30
		pane.playSound(self.sounds.write, 0, 0.35)
	end
end

function makeAndSpawnNote()
	local text = widget.getText("writebox")
	local color = widget.getSelectedOption("colorpicker")
	local note = root.createItem("stickynote" .. self.colors[color])
	text = text:gsub("^%s*(.-)%s*$", "%1") -- strip leading/trailing whitespace
	if text == "" then
		note.parameters.description = "I maybe should have written something before I peeled this off..."
		note.parameters.floranDescription = "Floran jusst enjoy peeling thingsss."
		note.parameters.glitchDescription = "Bewildered. What possessed me to peel this off without writing anything?"
		note.parameters.novakidDescription = "Aww, heck. Did I forget to write anythin' on this?"
	else
		note.parameters.description = "It says, '" .. text .. "'"
		note.parameters.floranDescription = "Note sssays, '" .. text .. "'"
		note.parameters.glitchDescription = "Remindful. '" .. text .. "'"
		note.parameters.novakidDescription = "It says, '" .. text .. "'"
	end
	oldNoteCount = player.hasCountOfItem(note, true)
	player.giveItem(note)
	if player.hasCountOfItem(note, true) > oldNoteCount then
		pane.playSound(self.sounds.peel, 0, 1.5)
		world.sendEntityMessage(player.id(), "consumeNote")
	else
		local e = "Error creating stickynote with parameters:/n/n"
		for k,v in pairs(note.parameters) do
			e = e .. "  " .. tostring(k) .. " : " .. tostring(v) .. "/n"
		end
		e = e .. "/n  inputText : " .. text .. "/n  inputColor : " .. color
		sb.logError(e)
	end
end