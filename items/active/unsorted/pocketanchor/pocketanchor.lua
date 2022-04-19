require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	self.timer = 3
	self.fireOffset = config.getParameter("fireOffset")
	script.setUpdateDelta(10)
end

function update(dt, fireMode, shiftHeld, moves)
	if (0==world.gravity(entity.position())) then
		status.removeEphemeralEffect("pocketanchorstat")
	else
		status.addEphemeralEffect("pocketanchorstat", 1)
		mcontroller.controlModifiers({
			speedModifier = self.boostAmount,
			liquidJumpModifier = 0,
			liquidForce = 300,
			liquidImpedance = 0.1
		})
	end
end

function uninit()
	status.removeEphemeralEffect("pocketanchorstat")
end
