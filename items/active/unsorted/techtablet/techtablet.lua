function activate(fireMode)
    if fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config")
	elseif fireMode == "alt" then
		--activeItem.interact("OpenCraftingInterface", "/objects/power/isn_radiostation/configs/isn_miningvendor.config")
		activeItem.interact("ScriptPane", "/interface/scripted/vehiclerepair/vehiclerepairgui.config")
	end
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end