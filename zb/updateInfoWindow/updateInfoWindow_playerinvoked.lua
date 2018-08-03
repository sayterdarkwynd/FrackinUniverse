
timer = 0
texts = nil
errored = false

--	TO DO:
-- Rewrite the system so instead of opening new windows, you can list between mods

function init()
	local passed, err = pcall(function()
		local pending = status.statusProperty("zb_updatewindow_pending", nil)
		local versions = status.statusProperty("zb_updatewindow_versions", {})
		
		if pending then
			if #pending > 0 then
				local data = root.assetJson("/zb/updateInfoWindow/data.config")
				texts = root.assetJson(data[pending[1]].file)
				
				widget.setText("textScrollBox.text", checkString(texts.welcome, "welcome"))
				widget.setText("version", texts.version)
				widget.setImage("title", data[pending[1]].image or "/assetmissing.png")
				
				if data[pending[1]].image then
					local imageSize = root.imageSize(data[pending[1]].image)
					local widgetPosition = widget.getPosition("title")
					widgetPosition[1] = widgetPosition[1] - imageSize[1] * 0.5
					widgetPosition[2] = widgetPosition[2] - imageSize[2] * 0.5
					widget.setPosition("title", widgetPosition)
				end
				
				if versions[pending[1]] ~= texts.version then
					widget.setButtonEnabled("close", false)
					timer = data.Data.minimumUptime
				end
			end
		else
			pane.dismiss()
		end
	end)
	
	if not passed then
		sb.logError("[ZB] UPDATE WINDOW ERRORED")
		sb.logError("Pending list:\n%s\nError:\n%s", status.statusProperty("zb_updatewindow_pending", nil), err)
		sb.logError("")
		
		errored = true
		widget.setText("textScrollBox.text", "An error has occured. Please report this error with a log attached.")
		widget.setButtonEnabled("close", true)
		widget.setText("close", "Dismiss")
	end
end

function update(dt)
	if errored then return end
	
	if timer > 0 then
		timer = timer - dt
		widget.setText("close", tostring(math.ceil(timer)))
	else
		widget.setButtonEnabled("close", true)
		widget.setText("close", "Dismiss")
	end
end

function uninit()
	if errored then return end
	
	if timer > 0 then
		player.interact("ScriptPane", "/zb/updateInfoWindow/updateInfoWindow.config")
		return
	else
		local pending = status.statusProperty("zb_updatewindow_pending", nil)
		if pending then
			local versions = status.statusProperty("zb_updatewindow_versions", {})
			versions[pending[1]] = texts.version
			status.setStatusProperty("zb_updatewindow_versions", versions)
			
			table.remove(pending, 1)
			if #pending < 1 then
				status.setStatusProperty("zb_updatewindow_pending", nil)
			else
				status.setStatusProperty("zb_updatewindow_pending", pending)
				player.interact("ScriptPane", "/zb/updateInfoWindow/updateInfoWindow.config")
			end
		end
	end
end

function close()
	pane.dismiss()
end

function checkString(str, req)
	local rtn = ""
	local passed, err = pcall(function()
		local a, b = string.find(str, "#file#")
		if a == 1 then
			local text = root.assetJson(string.gsub(str, "#file#", ""))
			rtn = text[req]
		else
			rtn = str
		end
	end)
	
	if passed then
		return rtn.."\n\n"
	else
		sb.logError("[ZB] UPDATE WINDOW ERRORED")
		sb.logError("Pending list:\n%s\nError:\n%s", status.statusProperty("zb_updatewindow_pending", nil), err)
		sb.logError("")
		
		errored = true
		widget.setText("textScrollBox.text", "An error has occured. Please report this error with a log attached.")
		widget.setButtonEnabled("close", true)
		widget.setText("close", "Dismiss")
	end
end

function buttonInfo()
	widget.setText("textScrollBox.text", checkString(texts.info, "info"))
	
	widget.setButtonEnabled("buttonChangelog", true)
	widget.setButtonEnabled("buttonCredits", true)
	widget.setButtonEnabled("buttonInfo", false)
end

function buttonChangelog()
	widget.setText("textScrollBox.text", checkString(texts.changelog, "changelog"))
	
	widget.setButtonEnabled("buttonChangelog", false)
	widget.setButtonEnabled("buttonCredits", true)
	widget.setButtonEnabled("buttonInfo", true)
end

function buttonCredits()
	widget.setText("textScrollBox.text", checkString(texts.credits, "credits"))
	
	widget.setButtonEnabled("buttonChangelog", true)
	widget.setButtonEnabled("buttonCredits", false)
	widget.setButtonEnabled("buttonInfo", true)
end