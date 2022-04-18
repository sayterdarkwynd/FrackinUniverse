function init()
  modes = {
    AA = "/zb/researchTree/researchTree",
    AB = "/interface/scripted/mmutility/mmutility",
    BA = "/interface/scripted/statWindow/statWindow",
    BB = "/zb/questList/questList"
  }
  sfx = {
    AA = "",
    AB = "3",
    BA = "",
    BB = "2"
  }
end

function activate(fireMode, shiftHeld)
        key = string.format("%s%s",fireMode and "A" or "B", shiftHeld and "A" or "B")
	activeItem.interact("ScriptPane", modes[key]..".config", player.id())
	animator.playSound("activate"..sfx[key])
end

function update()
    activeItem.setArmAngle(mcontroller.crouching() and -0.15 or -0.5)
end
