
require "/zb/zb_util.lua"

viewing = "##albums##"
musicList = {}
playing = {}

function init()
	musicList = root.assetJson("/interface/scripted/fm_musicplayer/musiclist.config")
	widget.registerMemberCallback("scrollArea.list", "button", playButton)
	widget.setButtonEnabled("modeButton", false)

	if world.entityType(pane.sourceEntity()) ~= "object" then
		widget.setButtonEnabled("settingsButton", false)
	end

	for _, file in ipairs(musicList["##files##"]) do
		local temp = root.assetJson(file)
		if temp then
			musicList = zbutil.MergeTable(musicList, temp)
		end
	end

	populateMusicList()
end

function populateMusicList()
	widget.clearListItems("scrollArea.list")
	local listItem
	local searching = widget.getText("search")

	if viewing == "##albums##" then
		listItem = "scrollArea.list."..widget.addListItem("scrollArea.list")
		widget.setText(listItem..".name", "All")
		widget.setButtonEnabled(listItem..".button", false)

		local img = "/interface/scripted/fm_musicplayer/controls.png:album"
		widget.setButtonImages(listItem..".button", { base = img, hover = img, pressed = img, disabled = img })
		widget.setButtonEnabled(listItem..".button", false)
		widget.setImage("titleIcon", "/interface/scripted/fm_musicplayer/controls.png:album")

		for album, _ in pairs(musicList) do
			if album ~= "##album_icons##" and album ~= "##files##" then
				if not searching or string.find(string.lower(album), string.lower(searching)) then
					listItem = "scrollArea.list."..widget.addListItem("scrollArea.list")
					widget.setText(listItem..".name", album)
					widget.setData(listItem..".name", album)

					img = musicList["##album_icons##"][album] or "/interface/scripted/fm_musicplayer/icon_unsorted.png"
					widget.setButtonImages(listItem..".button", { base = img, hover = img, pressed = img, disabled = img })
					widget.setButtonEnabled(listItem..".button", false)
				end
			end
		end
	else
		if viewing then
			widget.setImage("titleIcon", musicList["##album_icons##"][viewing] or "/interface/scripted/fm_musicplayer/icon_unsorted.png")
		else
			widget.setImage("titleIcon", "/interface/scripted/fm_musicplayer/controls.png:album")
		end

		-- Slightly less efficient, but no need to copy shit
		for album, _ in pairs(musicList) do
			if album ~= "##album_icons##" and album ~= "##files##" then
				if not viewing or album == viewing then
					for _, tbl in ipairs(musicList[album]) do
						if not searching or string.find(string.lower(tbl.name), string.lower(searching)) then
							listItem = "scrollArea.list."..widget.addListItem("scrollArea.list")
							widget.setText(listItem..".name", tbl.name)
							widget.setData(listItem..".name", tbl)
						end
					end
				end
			end
		end
	end
end

function modeButton()
	if viewing == "##albums##" then
		local selected=widget.getListSelected("scrollArea.list")
		if not selected then
			widget.setButtonEnabled("modeButton", false)
			return
		end
		viewing = widget.getData("scrollArea.list."..selected..".name")
		widget.setText("titleText", viewing or "All")

		local img = "/interface/scripted/fm_musicplayer/controls.png:album"
		widget.setButtonImages("modeButton", { base = img, hover = img.."Hover", pressed = img })
	else
		local img = "/interface/scripted/fm_musicplayer/controls.png:play"
		widget.setButtonImages("modeButton", { base = img, hover = img.."Hover", pressed = img })
		widget.setButtonEnabled("modeButton", false)

		widget.setText("titleText", "Select an album")
		viewing = "##albums##"
	end

	widget.setText("search", "")
	populateMusicList()
end

function stopButton()
	if world.entityType(pane.sourceEntity()) == "object" then
		world.sendEntityMessage(pane.sourceEntity(), "turnOff")
	else
		world.sendEntityMessage(pane.sourceEntity(), "turnOff")
		world.sendEntityMessage(player.id(), "stopAltMusic", 2.0)
	end
end

function labelButton()
	world.sendEntityMessage(pane.sourceEntity(), "toggleLabel")
end

function settingsButton()
	if widget.active("settings") then
		widget.setVisible("settings", false)
		widget.setVisible("scrollArea", true)
	else
		widget.setVisible("settings", true)
		widget.setVisible("scrollArea", false)
	end
end

function listSelected()
	if viewing == "##albums##" then
		widget.setButtonEnabled("modeButton", true)
	end
end

function playButton()
	playing = widget.getData("scrollArea.list."..widget.getListSelected("scrollArea.list")..".name")

	if world.entityType(pane.sourceEntity()) == "object" then
		world.sendEntityMessage(pane.sourceEntity(), "changeMusic", playing.directory, playing.name)
	else
		world.sendEntityMessage(player.id(), "playAltMusic", {playing.directory}, 2.0)
	end
end

function rangeButton(wd)
	local range = string.gsub(wd, "range", "")
	range = tonumber(range)
	world.sendEntityMessage(pane.sourceEntity(), "setMusicRange", range)
end

