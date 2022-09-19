require "/scripts/vec2.lua"
--local foodThreshold=15
local maxFreeFlightTime=5 -- in seconds, the max stored flight time that is 'free' (Excluding boost)

function init()
	self.active=false
	self.baseBoostSpeed = 12
	self.boostSpeed = self.baseBoostSpeed
	self.forceDeactivateTime = 3
	self.bonusFlightTime=config.getParameter("bonusFlightTime",0)
	self.fallingParameters=config.getParameter("fallingParameters")
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
end

function uninit()
	animator.stopAllSounds("activate")
	handleEffects(false)
end

function handleFuel(dt)
	self.fuelTimer=math.min(math.max((self.fuelTimer or 0)+dt,0),maxFreeFlightTime)
	if self.fuelTimer >= maxFreeFlightTime then
		if (self.soundTimer or 0)<=0.0 then
			animator.playSound("recharge")
		end
		self.soundTimer = 10
		status.addEphemeralEffect("flightRechargedIndicator")
	else
		self.soundTimer=math.max(0,((self.soundTimer or 0)-math.abs(dt)))
	end
end

function handleEffects(on)
	if on then
		status.addEphemeralEffects{{effect = "elduukharflight", duration = 2}}
		status.addEphemeralEffects{{effect = "lowgravflighttech", duration = 2}}
	else
		status.clearPersistentEffects("glide")
		self.boostSpeed = self.baseBoostSpeed
		status.removeEphemeralEffect("lowgravflighttech")
	end
end

function update(args)
	if not self.specialLast and args.moves["special1"] then	--toggle on
		attemptActivation()
	end

	self.specialLast = args.moves["special1"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	if (status.resource("energy") < 1) or (mcontroller.liquidPercentage() >= 0.50) then
		deactivate()
	end

	if self.active and ((not mcontroller.onGround() or args.moves["up"])) and (not mcontroller.zeroG()) and (not mcontroller.liquidMovement()) and status.overConsumeResource("energy", 0.0001) then -- do we have energy and the ability is active?
		handleEffects(true)
		--enable air physics
		mcontroller.controlParameters(self.fallingParameters or {})
		mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed or 0))

		-- boost in direction pressed
		local direction = {((args.moves["right"] and 1) or 0) + ((args.moves["left"] and -1) or 0),((args.moves["up"] and 1) or 0) + ((args.moves["down"] and -1) or 0)} -- set default
		self.boostSpeed = math.min(self.boostSpeed + args.dt,55) -- prevent super-rapid movement
		self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed)
		mcontroller.controlApproachVelocity(self.boostVelocity, 30)
		-- end boost

		-- stamina cost for flight, based on current speed / 100, plus a modifier value
		local useExhausted,useGreater,useLesser
		if self.fuelTimer > 0 then
			if (args.moves["down"]) or (args.moves["left"]) or (args.moves["right"]) or (args.moves["up"]) then
				useLesser=true
			end
		else
			if (args.moves["down"]) or (args.moves["left"]) or (args.moves["right"]) or (args.moves["up"]) then
				useExhausted=true
			else
				useGreater=true
			end
		end
		status.setPersistentEffects("glide", {{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}})
		local fuelCost = (((self.boostSpeed/100)*((((direction[1]~=0) or (direction[2]>0)) and 1) or ((direction[2]<0) and -1) or 0)) + ((useGreater and 0.05) or (useLesser and 0.01) or (useExhausted and 0.55) or 0)) - (self.bonusFlightTime or 0)
		if fuelCost>0 then
			status.overConsumeResource("energy",fuelCost)
		elseif fuelCost<0 then
			status.modifyResource("energy",-1*fuelCost)
		end
		handleFuel(-1*args.dt)
		checkForceDeactivate(args.dt) -- force deactivation
	else
		handleEffects(false)
		handleFuel(args.dt)
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
		handleEffects(false)
		status.addEphemeralEffects{{effect = "nofalldamage", duration = 2}}
	end
	self.active = false
end
