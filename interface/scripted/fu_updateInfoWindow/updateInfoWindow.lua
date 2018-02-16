
timer = 0

function init()
	data = root.assetJson("/_FUversioning.config")
	credits = root.assetJson("/_FUcredits.config")
	texts = root.assetJson("/interface/scripted/fu_updateInfoWindow/texts.config")
	
	widget.setText("version", "FU "..data.version)
	widget.setText("textScrollBox.text", texts.welcome)
	
	if status.statusProperty("FUversion", "0") ~= data.version then
		widget.setButtonEnabled("close", false)
		timer = data.minimumUptime
	end
end

function update(dt)
	if timer > 0 then
		timer = timer - dt
		widget.setText("close", tostring(math.ceil(timer)))
	else
		widget.setButtonEnabled("close", true)
		widget.setText("close", "Dismiss")
	end
end

function uninit()
	if timer > 0 then
		player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindow.config")
		return
	end
	status.setStatusProperty("FUversion", data.version)
end

function close()
	pane.dismiss()
end

function buttonInfo()
	widget.setText("textScrollBox.text", texts.info)
	
	widget.setButtonEnabled("buttonChangelog", true)
	widget.setButtonEnabled("buttonCredits", true)
	widget.setButtonEnabled("buttonInfo", false)
end

function buttonChangelog()
	widget.setText("textScrollBox.text", data.text)
	
	widget.setButtonEnabled("buttonChangelog", false)
	widget.setButtonEnabled("buttonCredits", true)
	widget.setButtonEnabled("buttonInfo", true)
end

function buttonCredits()
	widget.setText("textScrollBox.text", credits.credits)
	
	widget.setButtonEnabled("buttonChangelog", true)
	widget.setButtonEnabled("buttonCredits", false)
	widget.setButtonEnabled("buttonInfo", true)
end