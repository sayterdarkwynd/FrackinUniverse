function activate(fireMode)
	activeItem.interact("ScriptPane", "/interface/scripted/fu_tutorialQuestList/fu_tutorialQuestList.config", player.id())
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end