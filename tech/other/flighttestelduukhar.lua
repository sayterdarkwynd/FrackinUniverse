require "/scripts/vec2.lua"

function init()
	--self.energyCostPerSecond = config.getParameter("energyCostPerSecond")--not used
	self.active=false
	self.available = true
	--self.species = world.entitySpecies(entity.id())
	self.timer = 0
	self.boostSpeed = 12
	self.active=false
	self.available = true
	self.forceDeactivateTime = 3
	self.fuelTimer = 0 --failsafe value. default to no stamina so elduukhar have to wait before they can fly.
	self.soundTimer = 60
	self.bonusFlightTime=config.getParameter("bonusFlightTime",0)
	self.fallingParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function uninit()
	animator.stopAllSounds("activate")
	status.clearPersistentEffects("glide")
	animator.setParticleEmitterActive("feathers", false)
end

function checkFood()
	-- make sure flight stamina never exceeds limits
	if not self.fuelTimer then self.fuelTimer = 0 end
	if self.fuelTimer == 300 then
		animator.playSound("recharge")
		status.addEphemeralEffects{{effect = "flightRecharge", duration = 0.15}}
		animator.setParticleEmitterActive("feathers", true)
		self.soundTimer = 60
	else
		animator.setParticleEmitterActive("feathers", false)
		self.soundTimer = 60
	end
	if self.fuelTimer < 0 then
		self.fuelTimer = 0
	end
	if self.fuelTimer > 300 then
		self.fuelTimer = 300
	end
	-- end flight stamina check
end

function boost(direction)
	self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed)
	if self.boostSpeed > 55 then -- prevent super-rapid movement
		self.boostSpeed = 55
	end
end

function update(args)
	--fuel stamina check
	--sb.logInfo(self.fuelTimer)
	if self.soundTimer <= 0 then --sound effect timer for flight timer
		self.soundTimer = 60
	else
		self.soundTimer = self.soundTimer - 1
	end

	if not self.specialLast and args.moves["special1"] then	--toggle on
		attemptActivation()
	end

	self.specialLast = args.moves["special1"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	if status.resource("energy") < 1 then
		deactivate()
	end

	if self.active and status.overConsumeResource("energy", 0.0001) and not mcontroller.zeroG() and not mcontroller.liquidMovement() then -- do we have energy and the ability is active?
		checkFood()
		status.addEphemeralEffects{{effect = "elduukharflight", duration = 2}}
		status.addEphemeralEffects{{effect = "lowgravflighttech", duration = 2}}
		self.upVal = args.moves["up"]	--set core movement variables
		self.downVal = args.moves["down"]
		self.leftVal = args.moves["right"]
		self.rightVal = args.moves["left"]
		self.runVal = args.moves["run"]

		--enable air physics
		mcontroller.controlParameters(self.fallingParameters or {})
		mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed or 0))

		-- boost in direction pressed
		local direction = {0, 0} -- set default
		if self.upVal then direction[2] = direction[2] + 1 end
		if self.downVal then direction[2] = direction[2] - 1 end
		if self.leftVal then direction[1] = direction[1] + 1 end
		if self.rightVal then direction[1] = direction[1] - 1 end

		self.boostSpeed = self.boostSpeed + args.dt
		boost(direction)
		mcontroller.controlApproachVelocity(self.boostVelocity, 30)
		-- end boost

		-- stamina cost for flight, based on current speed / 100, plus a modifier value
		self.fuelCostLesser = ((self.boostSpeed/100) + 0.01) - (self.bonusFlightTime or 0)
		self.fuelCostGreater = ((self.boostSpeed/100)	+ 0.05) - (self.bonusFlightTime or 0)
		self.fuelCostExhausted = ((self.boostSpeed/100)	+ 0.55) - (self.bonusFlightTime or 0)

		if self.fuelTimer < 0 then self.fuelTimer = 0 end
		if self.fuelTimer > 0 then
			self.fuelTimer = self.fuelTimer - 1
			status.overConsumeResource("energy", self.fuelCostGreater)
			if self.runVal and not self.downVal and not self.leftVal and not self.rightVal and not self.upVal then
				status.setPersistentEffects("glide", {
					--{stat = "gliding", amount = 1},
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}
				})
			else
				status.setPersistentEffects("glide", {
					--{stat = "gliding", amount = 0},
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}
				})
			end
		else
			if self.runVal and not self.downVal and not self.leftVal and not self.rightVal and not self.upVal then
				status.overConsumeResource("energy", self.fuelCostLesser)
				status.setPersistentEffects("glide", {
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}
				})
			else
				status.overConsumeResource("energy", self.fuelCostExhausted)
				status.setPersistentEffects("glide", {
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}
				})
			end

		end
		checkForceDeactivate(args.dt) -- force deactivation
	else
		checkFood()
		self.fuelTimer = self.fuelTimer + 1 -- when not active, the stamina to fly regenerates.
	end
end

function attemptActivation()
	if not self.active then
		activate()
	elseif self.active then
		deactivate()
		if not self.forceTimer then
			self.forceTimer = 0
		end
	end
end

function checkForceDeactivate(dt)
	if self.forceTimer then
		self.forceTimer = self.forceTimer + dt
		if self.forceTimer >= self.forceDeactivateTime then
			deactivate()
			self.forceTimer = nil
		else
			attemptActivation()
		end
		return true
	else
		return false
	end
end

function activate()
	if not self.active then
		animator.playSound("activate")
	end
	self.active = true
end

function deactivate()
	if self.active then
		status.clearPersistentEffects("glide")
		animator.setParticleEmitterActive("feathers", false)
		self.boostSpeed = 8
		status.addEphemeralEffects{{effect = "nofalldamage", duration = 2}}
	end
	self.active = false
end
