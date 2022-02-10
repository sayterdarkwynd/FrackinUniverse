require "/scripts/vec2.lua"

function init()
	self.boostTime = config.getParameter("boostTime")
	self.boostSpeed = config.getParameter("boostSpeed")
	self.boostForce = config.getParameter("boostForce")
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
	self.gravActive=false
	idle()
	self.checkWorldOnce=false
end

function uninit()
	idle()
end

function update(args)
	if not self.checkWorldOnce then
		self.onOwnShip = status.statusProperty("player.ownShipWorldId") == status.statusProperty("player.worldId")
		self.checkWorldOnce=true
	end
	local jumpBonus = 1 + status.stat("jumptechBonus")
	local jumpActivated = args.moves["jump"] and not self.lastJump
	self.lastJump = args.moves["jump"]
	self.stateTimer = math.max(0, self.stateTimer - args.dt)

	if not args.moves["special1"] and self.specialLast then
		self.gravActive = not self.gravActive
	end
	self.specialLast=args.moves["special1"]

	if self.gravActive then
		if self.onOwnShip or status.overConsumeResource("energy", 0.07) then
			status.addEphemeralEffects{{effect = "nofalldamage", duration = 0.2 * jumpBonus}}
		else
			self.gravActive=false
		end
	end

	if self.state == "idle" then

		if jumpActivated and canRocketJump() then
			local direction = {(args.moves["right"] and 1 or 0) + (args.moves["left"] and -1 or 0) , (args.moves["up"] and 1 or 0) + (args.moves["down"] and -1 or 0)}

			if vec2.eq(direction, {0, 0}) then direction = {0, 0} end
				boost(direction,jumpBonus)
			end
		elseif self.state == "boost" then
			local direction = {(args.moves["right"] and 1 or 0) + (args.moves["left"] and -1 or 0) , (args.moves["up"] and 1 or 0) + (args.moves["down"] and -1 or 0)}

			if vec2.eq(direction, {0, 0}) then direction = {0, 0} end
			boost(direction,jumpBonus)
			if args.moves["jump"] then
			if self.onOwnShip or status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
				mcontroller.controlApproachVelocity(self.boostVelocity, self.boostForce*jumpBonus)
			else
				idle()
			end
		else
			idle()
		end
	end

	animator.setFlipped(mcontroller.facingDirection() < 0)
end

function canRocketJump()
	return not mcontroller.canJump() and not status.statPositive("activeMovementAbilities")
end

function boost(direction,jumpBonus)
	self.state = "boost"
	self.stateTimer = self.boostTime
	self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed*jumpBonus)
	tech.setParentState()
	animator.setAnimationState("boosting", "on")
	animator.setParticleEmitterActive("boostParticles", true)
end

function idle()
	self.state = "idle"
	self.stateTimer = 0
	status.clearPersistentEffects("movementAbility")
	tech.setParentState()
	animator.setAnimationState("boosting", "off")
	animator.setParticleEmitterActive("boostParticles", false)
end
