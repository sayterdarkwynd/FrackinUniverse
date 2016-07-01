function init()
	self.active = false
	self.lastYVelocity = 0
	self.bounceTimer = 0
end

function input(args)
	if args.moves["special"] == 1 ~= self.active then
		if self.active then
			return "deactivate"
		else
			return "activate"
		end
	end
end

function update(args)
	local energyUsageRate = tech.parameter("energyUsageRate")
	local bounceCollisionPoly = tech.parameter("bounceCollisionPoly")
	local bounceFactor = tech.parameter("bounceFactor")
	
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
	and tech.consumeTechEnergy(energyUsageRate * args.dt) then
		status.setPersistentEffects("bounceTech", {{stat = "fallDamageMultiplier", baseMultiplier = -2}})
		self.active = true
		tech.setAnimationState("bouncing", "on")
		tech.playSound("activate")
	elseif self.active and (deactivate or (self.active and not tech.consumeTechEnergy(energyUsageRate * args.dt))) then
		status.clearPersistentEffects("bounceTech")
		self.active = false
		tech.setAnimationState("bouncing", "off")
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
