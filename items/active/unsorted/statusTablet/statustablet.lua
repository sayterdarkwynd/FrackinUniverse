function init()
  modes = {
    AA = "/zb/researchTree/researchTree",
    AB = "/interface/scripted/mmutility/mmutility",
    BA = "/interface/scripted/statWindow/statWindow",
    BB = "/zb/questList/questList"
  }
end

function activate(fireMode, shiftHeld)
	activeItem.interact("ScriptPane", modes[string.format("%s%s",fireMode and "A" or "B", shiftHeld and "A" or "B")]..".config", player.id())
	animator.playSound("activate")
end

function update()
    activeItem.setArmAngle(mcontroller.crouching() and -0.15 or -0.5)
end
