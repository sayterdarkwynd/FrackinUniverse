
texts = nil
errored = false
checkedAll = false
data = nil
modslist = {}
index = 1
timer = nil
versionIndex = {}

function init()
	local passed, err = pcall(function()
		data = root.assetJson("/zb/updateInfoWindow/data.config")
		modslist = status.statusProperty("zb_updatewindow_pending", {}) or {}

		widget.setButtonEnabled("close", false)
		widget.setButtonEnabled("buttonPrevious", false)
		if #modslist <= 0 then
			checkedAll = true
			timer = 0

			for mod, _ in pairs(data) do
				if mod ~= "Data" then
					table.insert(modslist, mod)
				end
			end
		end

		if #modslist == 1 then
			widget.setButtonEnabled("buttonNext", false)
		end

		if not timer then
			timer = data.Data.minimumUptime
		end

		displayInfo()
	end)

	if not passed then
		sb.logError("[ZB] UPDATE WINDOW ERRORED")
		sb.logError("mods list:\n%s\nError:\n%s", status.statusProperty("zb_updatewindow_pending", {}) or {}, err)
		sb.logError("")

		errored = true
		widget.setText("textScrollBox.text", "An error has occured. Please report this error with a log attached.")
		widget.setButtonEnabled("close", true)
		--widget.setText("close", "Dismiss")
		widget.setText("close", "")
	end
end

function update(dt)
	--if timer then
	--	if timer >= 0 then
	--		timer = timer - dt
	--		widget.setText("close", math.ceil(timer))
	--	else
			checkedAll = true
			widget.setButtonEnabled("close", true)
			--widget.setText("close", "Dismiss")
			widget.setText("close", "")
	--	end
	--end
end

function displayInfo()
	texts = root.assetJson(data[modslist[index]].file)
	versionIndex[modslist[index]] = texts.version

	widget.setButtonEnabled("buttonChangelog", true)
	widget.setButtonEnabled("buttonCredits", true)
	widget.setButtonEnabled("buttonInfo", true)

	widget.setText("textScrollBox.text", "\n"..checkString(texts.welcome, "welcome").."\n\n")
	widget.setText("version", texts.version)

	if data[modslist[index]].image then
		local imageSize = root.imageSize(data[modslist[index]].image)
		local widgetPosition = {150, 232}
		widgetPosition[1] = widgetPosition[1] - imageSize[1] * 0.5
		widgetPosition[2] = widgetPosition[2] - imageSize[2] * 0.5
		widget.setPosition("title", widgetPosition)
		widget.setImage("title", data[modslist[index]].image)
	else
		widget.setImage("title", "/assetmissing.png")
	end
end

function uninit()
	if errored then return end

	if not checkedAll then
		player.interact("ScriptPane", "/zb/updateInfoWindow/updateInfoWindow.config")
		return
	else
		local pending = status.statusProperty("zb_updatewindow_pending", {}) or {}
		local versions = status.statusProperty("zb_updatewindow_versions", {}) or {}
		for _, mod in ipairs(pending) do
			versions[mod] = versionIndex[mod]
			status.setStatusProperty("zb_updatewindow_versions", versions)
		end
		status.setStatusProperty("zb_updatewindow_pending", nil)
	end
end

function close()
	pane.dismiss()
end

function checkString(str, req)
	local rtn = ""
	local passed, err = pcall(function()
		local a = string.find(str, "#file#")
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
		sb.logError("Pending list:\n%s\nError:\n%s", status.statusProperty("zb_updatewindow_pending", {}) or {}, err)
		sb.logError("")

		errored = true
		widget.setText("textScrollBox.text", "An error has occured. Please report this error with a log attached.")
		widget.setButtonEnabled("close", true)
		--widget.setText("close", "Dismiss")
		widget.setText("close", "")
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

function buttonNext()
	index = index + 1
	if index >= #modslist then
		checkedAll = true
		widget.setButtonEnabled("close", true)
		widget.setButtonEnabled("buttonNext", false)
	end

	displayInfo()
	widget.setButtonEnabled("buttonPrevious", true)
end

function buttonPrevious()
	index = index - 1
	if index <= 1 then
		widget.setButtonEnabled("buttonPrevious", false)
	end

	displayInfo()
	widget.setButtonEnabled("buttonNext", true)
end
