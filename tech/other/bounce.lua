function init()
	self.active = false
	self.lastYVelocity = 0
	self.bounceTimer = 0
end

function input(args)
	if args.moves["special1"] ~= self.active then
		if self.active then
			return "deactivate"
		else
			return "activate"
		end
	end
end

function update(args)
	local energyUsageRate = config.getParameter("energyUsageRate")
	local bounceCollisionPoly = config.getParameter("bounceCollisionPoly")
	local bounceFactor = config.getParameter("bounceFactor")
	
	local curYVelocity = mcontroller.yVelocity()
	local yVelChange = curYVelocity - self.lastYVelocity
	self.lastYVelocity = curYVelocity
	
	local activate = curYVelocity < -65
	local deactivate = self.bounceTimer <= 0 and curYVelocity >= -30
	
	if activate then
		self.bounceTimer = 1
	else
		self.bounceTimer = self.bounceTimer - args.dt
	end
	
	if not self.active and activate and world.resolvePolyCollision(bounceCollisionPoly, mcontroller.position(), 1)
	and status.overConsumeResource("energy", energyUsageRate * args.dt) then
		status.setPersistentEffects("bounceTech", {{stat = "fallDamageMultiplier", effectiveMultiplier = 0}})
		self.active = true
		animator.setAnimationState("bouncing", "on")
		animator.playSound("activate")
	elseif self.active and (deactivate or (self.active and not status.overConsumeResource("energy", energyUsageRate * args.dt))) then
		status.clearPersistentEffects("bounceTech")
		self.active = false
		animator.setAnimationState("bouncing", "off")
	end
	
	if self.active then
		mcontroller.controlParameters({
			standingPoly = bounceCollisionPoly,
			crouchingPoly = bounceCollisionPoly,
			collisionPoly = bounceCollisionPoly,
			bounceFactor = bounceFactor,
			jumpSpeed = 0
		})
	end
end
