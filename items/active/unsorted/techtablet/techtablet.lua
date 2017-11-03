function activate(fireMode)
    if fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/techshop/techshop.config")
		animator.playSound("activate")
	elseif fireMode == "alt" then
		activeItem.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config")
		animator.playSound("activate")
	end
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end