function activate(fireMode)
    if fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/statWindow/statWindow.config", player.id())
    elseif fireMode == "alt" then
		activeItem.interact("ScriptPane", "/interface/scripted/fu_tutorialQuestList/fu_tutorialQuestList.config", player.id())
    end
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end