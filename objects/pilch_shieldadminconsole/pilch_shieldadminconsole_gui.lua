currentStatusText = ""

function init()
	world.sendEntityMessage(pane.sourceEntity(), "setActiveAnimation")
end

function update(dt)
	checkRelationships()
end

function dismissed()
	world.sendEntityMessage(pane.sourceEntity(), "setInactiveAnimation")
end

function checkRelationships()
	local statusText = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_status") or ""
	if (statusText ~= currentStatusText) then
		if (string.sub(statusText, 1, 5) == "^red;") then
			pane.playSound("/sfx/interface/clickon_error.ogg")
			widget.setImage("statusImage", "/objects/pilch_shieldgenerator/interface/titlebar.png:red")
		elseif (string.sub(statusText, 1, 7) == "^green;") then
			pane.playSound("/sfx/interface/playerstatuscritical.ogg")
			widget.setImage("statusImage", "/objects/pilch_shieldgenerator/interface/titlebar.png:green")
		end
		currentStatusText = statusText
		widget.setText("statusLabel", statusText)
	end
	if (player.isAdmin()) then
		widget.setButtonEnabled("purgeButton", true)
	else
		widget.setText("warningLabel", "Admin privileges are required to operate.")
		widget.setButtonEnabled("purgeButton", false)
	end
end

---------------------------------------------------------
-- widget callbacks
---------------------------------------------------------
function quitButton()
	pane.dismiss()
end

function purgeButton()
	world.sendEntityMessage(pane.sourceEntity(), "purge")
end