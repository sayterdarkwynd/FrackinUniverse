function activate(fireMode, shiftHeld)
	activeItem.interact("ScriptPane", "/interface/scripted/xcustomcodex/xcodexui.config")
	animator.playSound("enable")
end


function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end