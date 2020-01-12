function activate(fireMode, shiftHeld)
    if fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/mechassembly/mechassemblygui.config")
    elseif fireMode == "alt" then
		activeItem.interact("ScriptPane", "/interface/mechfuel/mechfuel.config")
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






