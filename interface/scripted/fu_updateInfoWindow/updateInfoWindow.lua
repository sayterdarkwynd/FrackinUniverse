
timer = 0

function init()
	local data = root.assetJson("/_FUversioning.config")
	widget.setText("textScrollBox.text", data.text)
	widget.setText("version", "FU "..data.version)
	widget.setButtonEnabled("close", false)
	timer = data.minimumUptime
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
	end
end