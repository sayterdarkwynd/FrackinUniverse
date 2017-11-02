function activate(fireMode)
    if fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/fm_musicplayer/fm_musicplayer.config")
	elseif fireMode == "alt" then
		world.sendEntityMessage(player.id(), "stopAltMusic", 2.0)
	end
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end