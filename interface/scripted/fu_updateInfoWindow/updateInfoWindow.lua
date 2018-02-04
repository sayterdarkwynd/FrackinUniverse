
timer = 0

function init()
	data = root.assetJson("/_FUversioning.config")
	widget.setText("textScrollBox.text", data.text)
	widget.setText("version", "FU "..data.version)
	widget.setButtonEnabled("close", false)
	if status.statusProperty("FUversion", "0") ~= data.version then
		timer = data.minimumUptime
	else
		timer = 0
	end
end

function close()
	pane.dismiss()
end

function update(dt)
	if timer > 0 then
		timer = timer - dt
		widget.setText("close", tostring(math.ceil(timer)))
	else
		widget.setButtonEnabled("close", true)
		widget.setFontColor("close", "#FFFFFF")
		widget.setText("close", "Close")
	end
end

function uninit()
	if timer > 0 then
		player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindow.config")
		return
	end
	status.setStatusProperty("FUversion", data.version)
end