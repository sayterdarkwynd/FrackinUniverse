fieldOptions = {}
currentStatusText = ""
dirtyCounter = 0

function init()
	loadOptions()
	checkRelationships()
end

function update(dt)
	checkRelationships()
end

function dismissed()
	saveOptions()
end

function loadOptions()
	fieldOptions.applyProtected = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_protected")
	if (fieldOptions.applyProtected == nil) then fieldOptions.applyProtected = true end
	fieldOptions.applyBreathable = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_breathable")
	if (fieldOptions.applyBreathable == nil) then fieldOptions.applyBreathable = true end
	local gravity = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_gravity") or {}
	fieldOptions.applyGravity = gravity.applyGravity or false
	fieldOptions.gravityLevel = gravity.gravityLevel or 80
	fieldOptions.hideMode = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_hidden") or -1
	fieldOptions.debugEnabled = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_debug") or false
	fieldOptions.active = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_active") or false

	gravityLevelSanityCheck()

	widget.setChecked("applyProtectedCheckBox", fieldOptions.applyProtected)
	widget.setChecked("applyBreathableCheckBox", fieldOptions.applyBreathable)
	widget.setChecked("debugCheckBox", fieldOptions.debugEnabled)
	widget.setChecked("applyGravityCheckBox", fieldOptions.applyGravity)
	widget.setSelectedOption("hideRadioGroup", fieldOptions.hideMode)
	widget.setChecked("activateButton", fieldOptions.active)
end

function saveOptions()
	world.sendEntityMessage(pane.sourceEntity(), "setProtected", fieldOptions.applyProtected)
	world.sendEntityMessage(pane.sourceEntity(), "setBreathable", fieldOptions.applyBreathable)
	world.sendEntityMessage(pane.sourceEntity(), "setGravity", fieldOptions.applyGravity, fieldOptions.gravityLevel)
	world.sendEntityMessage(pane.sourceEntity(), "setDebugMode", fieldOptions.debugEnabled)
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
	local dirty = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_dirty") or 0
	if (dirty ~= dirtyCounter) then
		loadOptions()
		dirtyCounter = dirty
	end
	local isWired = world.getObjectParameter(pane.sourceEntity(), "pilch_shieldgenerator_wired") or false
	if (fieldOptions.active) then
		widget.setButtonEnabled("applyProtectedCheckBox", false)
		widget.setButtonEnabled("applyBreathableCheckBox", false)
		widget.setButtonEnabled("applyGravityCheckBox", false)
		widget.setButtonEnabled("gravityLevelMinus", false)
		widget.setButtonEnabled("gravityLevelPlus", false)
		for i = -1, 1 do
			widget.setOptionEnabled("hideRadioGroup", i, false)
		end
		widget.setVisible("gravityLevelTextBox", false)
	else
		widget.setButtonEnabled("applyProtectedCheckBox", true)
		widget.setButtonEnabled("applyBreathableCheckBox", true)
		widget.setButtonEnabled("applyGravityCheckBox", true)
		widget.setButtonEnabled("gravityLevelMinus", fieldOptions.applyGravity)
		widget.setButtonEnabled("gravityLevelPlus", fieldOptions.applyGravity)
		for i = -1, 1 do
			widget.setOptionEnabled("hideRadioGroup", i, true)
		end
		widget.setVisible("gravityLevelTextBox", fieldOptions.applyGravity)
	end
	if (isWired) then
		widget.setButtonEnabled("activateButton", false)
	else
		widget.setButtonEnabled("activateButton", true)
	end
	if 	(fieldOptions.applyProtected == false) and
		(fieldOptions.applyBreathable == false) and
		(fieldOptions.applyGravity == false) then
		widget.setButtonEnabled("activateButton", false)
	end
	if (player.isAdmin()) then
		if (fieldOptions.active) then
			widget.setButtonEnabled("overrideCheckBox", false)
		else
			widget.setButtonEnabled("overrideCheckBox", true)
		end
		widget.setVisible("overrideLabel", true)
		widget.setVisible("overrideCheckBox", true)
	else
		widget.setChecked("overrideCheckBox", false)
		widget.setButtonEnabled("overrideCheckBox", false)
		widget.setVisible("overrideLabel", false)
		widget.setVisible("overrideCheckBox", false)
	end
end

function gravityLevelSanityCheck()
	if (fieldOptions.gravityLevel) then
		if (fieldOptions.gravityLevel < -1000) then fieldOptions.gravityLevel = -1000 end
		if (fieldOptions.gravityLevel > 1000) then fieldOptions.gravityLevel = 1000 end
		widget.setText("gravityLevelTextBox", fieldOptions.gravityLevel)
	end
end

---------------------------------------------------------
-- widget callbacks
---------------------------------------------------------
function quitButton()
	pane.dismiss()
end

function applyProtectedCheckBox()
	fieldOptions.applyProtected = widget.getChecked("applyProtectedCheckBox")
	saveOptions()
end

function applyBreathableCheckBox()
	fieldOptions.applyBreathable = widget.getChecked("applyBreathableCheckBox")
	saveOptions()
end

function debugCheckBox()
	fieldOptions.debugEnabled = widget.getChecked("debugCheckBox")
	saveOptions()
end

function applyGravityCheckBox()
	fieldOptions.applyGravity = widget.getChecked("applyGravityCheckBox")
	saveOptions()
end

function gravityLevelTextBox()
	fieldOptions.gravityLevel = tonumber(widget.getText("gravityLevelTextBox"))
	gravityLevelSanityCheck()
	if (fieldOptions.gravityLevel) then saveOptions() end
end

function gravityLevelMinus()
	if (fieldOptions.gravityLevel) then fieldOptions.gravityLevel = fieldOptions.gravityLevel - 10 else fieldOptions.gravityLevel = -10 end
	gravityLevelSanityCheck()
	if (fieldOptions.gravityLevel) then saveOptions() end
end

function gravityLevelPlus()
	if (fieldOptions.gravityLevel) then fieldOptions.gravityLevel = fieldOptions.gravityLevel + 10 else fieldOptions.gravityLevel = 10 end
	gravityLevelSanityCheck()
	if (fieldOptions.gravityLevel) then saveOptions() end
end

function hideRadioGroup()
	world.sendEntityMessage(pane.sourceEntity(), "hide", widget.getSelectedOption("hideRadioGroup"))
end

function overrideCheckBox()

end

function activateButton()
	if (widget.getChecked("activateButton")) then
		world.sendEntityMessage(pane.sourceEntity(), "activate", widget.getChecked("overrideCheckBox"))
		fieldOptions.active = true
	else
		world.sendEntityMessage(pane.sourceEntity(), "deactivate")
		fieldOptions.active = false
	end
end