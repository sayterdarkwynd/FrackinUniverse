function activate(fireMode, shiftHeld)
    if shiftHeld then
		activeItem.interact("ScriptPane", "/zb/researchTree/researchTree.config")
		animator.playSound("activate")
    elseif fireMode == "primary" then
		activeItem.interact("ScriptPane", "/interface/scripted/techshop/techshop.config")
		animator.playSound("activate")
	elseif fireMode == "alt" then
		activeItem.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config")
		animator.playSound("activate")
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






