require "/scripts/rect.lua"

function init()
	--[[local velocity = status.statusProperty("ballisticVelocity")
	if not velocity then effect.expire() end
	mcontroller.setVelocity(velocity)]]
end

function update(dt)
	local stickingDirection = mcontroller.stickingDirection()
	if not stickingDirection then
		local angle = vec2.angle(mcontroller.velocity())
		mcontroller.setRotation(angle - math.pi / 2)
	else
		self.expireOnMove = true
	end

	if self.expireOnMove and (mcontroller.running() or mcontroller.walking()) then
		effect.expire()
	end

	mcontroller.controlParameters({
		standingPoly = { {-0.75, -2.0}, {-0.35, -2.5}, {0.35, -2.5}, {0.75, -2.0}, {0.75, -0.5}, {0.35, 0.25}, {-0.35, 0.25}, {-0.75, -0.5} },
		stickyCollision = true,
		stickyForce = 500
	})
end

function uninit()
	mcontroller.setRotation(0)
	mcontroller.setPosition(vec2.add(mcontroller.position(), {0, 1}))
end
