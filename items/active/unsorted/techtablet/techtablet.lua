function activate(fireMode, shiftHeld)
    if shiftHeld then
        activeItem.interact("ScriptPane", "/interface/scripted/mechassembly/mechassemblygui.config")
    elseif fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/techshop/techshop.config")
	elseif fireMode == "alt" then
		activeItem.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config")
	end
    animator.playSound("activate")
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end






