require "/scripts/vec2.lua"

function init()
	self.jetpackSpeed = config.getParameter("jetpackSpeed")
	self.jetpackForce = config.getParameter("jetpackForce")
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")

	self.holdingJump = false
	self.active = false
	self.lastYVel = mcontroller.yVelocity()
end

function applyTechBonus()
  self.jumpBonus = 1 + status.stat("jumptechBonus") -- apply bonus from certain items and armor
end

function update(args)
  applyTechBonus()
	if args.moves["jump"] and mcontroller.jumping() then
		self.holdingJump = true
	elseif not args.moves["jump"] then
		self.holdingJump = false
	end

	-- local jetpack = args.moves["jump"] and (mcontroller.yVelocity() - 5 <= self.lastYVel) and (args.moves["down"] and mcontroller.yVelocity() <= -40 or not args.moves["down"]) -- and not mcontroller.canJump() and not self.holdingJump
	local jetpack = args.moves["jump"] and (args.moves["down"] and mcontroller.yVelocity() <= -40 or not args.moves["down"]) and not mcontroller.canJump() and not self.holdingJump

	if jetpack and status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
		animator.setAnimationState("jetpack", "on")
		mcontroller.controlApproachYVelocity(self.jetpackSpeed, self.jetpackForce)

		if not self.active then
			animator.playSound("activate")
		end
		self.active = true
	else
		self.active = false
		animator.setAnimationState("jetpack", "off")
	end

	self.lastYVel = mcontroller.yVelocity()
end
