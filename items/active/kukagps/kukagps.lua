function activate(fireMode, shiftHeld)
    if fireMode == "primary" then
        activeItem.interact("ScriptPane", "/interface/kukagps/kukagps.config")
        animator.playSound("activate")
    else
        activeItem.interact("ScriptPane", "/interface/kukagps/kukagps.config")
        animator.playSound("activate2")
    end
    
end


function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end
