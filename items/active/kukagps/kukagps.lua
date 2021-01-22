function activate(fireMode, shiftHeld)
    if shiftHeld then
        activeItem.interact("ScriptPane", "/interface/kukagps/kukadungeon.config")
        animator.playSound("activate3")
    elseif fireMode == "primary" then
        activeItem.interact("ScriptPane", "/interface/kukagps/kukagps.config")
        animator.playSound("activate")
    elseif fireMode == "alt" then
        activeItem.interact("ScriptPane", "/interface/kukagps/kukadatetime.config")
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
