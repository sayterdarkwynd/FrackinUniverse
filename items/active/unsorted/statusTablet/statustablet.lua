function activate(fireMode)
	activeItem.interact("ScriptPane", "/interface/scripted/statWindow/statWindow.config", player.id())
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end