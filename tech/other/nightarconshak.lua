require "/scripts/vec2.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	initCommonParameters()
end

function initCommonParameters()
	self.energyCost = config.getParameter("energyCostPerSecond")
	self.bombTimer = 0
	self.conshakTimer = 0
	-- for status bar filling, below are required
	self.playerId = entity.id()
	self.maxConshakValue = 400
	self.barName = "conshakBar"
	self.barColor = {150,77,250,125}
	self.timerRemoveConshakBar = 0
end

function uninit()
	deactivate()
end

--display conshak bar
function displayBar()
	self.conshakPercent = self.conshakTimer / self.maxConshakValue
	if self.conshakPercent > 1.0 then
		self.conshakPercent = 1
	end

	if self.conshakTimer < 50 then
		self.barColor = {22,0,70,125}
	end
	if self.conshakTimer > 50 then
		self.barColor = {116,0,255,90}
	end
	if self.conshakTimer > 150 then
		self.barColor = {53,0,255,125}
	end
	if self.conshakTimer > 250 then
		self.barColor = {0,42,255,170}
	end
	if self.conshakTimer > 350 then
		self.barColor = {0,137,255,199}
	end
	if self.conshakTimer > 450 then
		self.barColor = {81,217,250,222}
	end

	if (self.conshakTimer > 0) then
		world.sendEntityMessage(self.playerId,"setBar","conshakBar",self.conshakPercent,self.barColor)
	else
		world.sendEntityMessage(self.playerId,"removeBar","conshakBar")
	end
end

function checkStance()
	if (self.conshakTimer < 400) then
		animator.setParticleEmitterActive("conshak", false)
	else
		animator.playSound("conshakActivate")
		world.sendEntityMessage(self.playerId,"removeBar","conshakBar")
	end
	if self.pressDown then
		 animator.setParticleEmitterActive("defenseStance", true)
		 animator.playSound("conshakCharge")
	else
		animator.setParticleEmitterActive("defenseStance", false)
		status.clearPersistentEffects("nightarconshak")
	end
	self.bombTimer = 8
end

function update(args)
	 if (self.timerRemoveConshakBar >=25) then
		 world.sendEntityMessage(entity.id(),"removeBar","conshakBar")	 --clear ammo bar
		 self.timerRemoveConshakBar = 0
	 else
		 self.timerRemoveConshakBar = self.timerRemoveConshakBar + 1
	 end

	local underground = undergroundCheck()
	local lightLevel = getLight()

	if not self.specialLast and args.moves["special1"] then
		attemptActivation()
		animator.playSound("activate")
	end

	self.specialLast = args.moves["special1"]
	self.pressDown = args.moves["down"]
	self.pressLeft = args.moves["left"]
	self.pressRight = args.moves["right"]
	self.pressUp = args.moves["up"]
	self.pressJump = args.moves["jump"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	-- make sure its dark, or they are underground
	if (lightLevel <= 60) or underground then
		if self.active then
			if self.bombTimer > 0 then
				self.bombTimer = math.max(0, self.bombTimer - args.dt)
			end
			if (self.pressDown) and not self.pressLeft and not self.pressRight and not self.pressUp and not self.pressJump then
				if (self.conshakTimer < 400) then
					displayBar()
					self.conshakTimer = self.conshakTimer + 1
				else
					self.conshakTimer = 0
					displayBar()
				end
				status.setPersistentEffects("nightarconshak", {
					{stat = "protection", effectiveMultiplier = 0.01},
					{stat = "powerMultiplier", effectiveMultiplier = 0.01},
					{stat = "maxEnergy", effectiveMultiplier = 0.05},
					{stat = "breathDepletionRate", effectiveMultiplier = 0.25},
					{stat = "breathRegenerationRate", effectiveMultiplier = 1.25},
					{stat = "foodDelta", amount = 0.25},
					{stat = "chargingConshak", amount = self.conshakTimer}
				})
				status.addEphemeralEffects{{effect = "chargeupConshak", duration = 0.1}}
				if self.bombTimer == 0 then
					checkStance()
				end

				if (self.conshakTimer >= 400) then
					animator.setParticleEmitterActive("defenseStance", false)
					animator.setParticleEmitterActive("conshak", true)
					local configBombDrop = { power = 0 }
					world.spawnProjectile("activeConshakCharged", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
					--status.addEphemeralEffects{{effect = "nightarconshakstat", duration = 60}}
					status.addEphemeralEffects{{effect = "detectmonsternightar", duration = 60}}
					self.conshakTimer = 0
				end

			else
				animator.setParticleEmitterActive("defenseStance", false)
				animator.setParticleEmitterActive("conshak", false)
				status.clearPersistentEffects("nightarconshak")
				status.clearPersistentEffects("detectmonsternightar")
				self.conshakTimer = 0
			end

			checkForceDeactivate(args.dt)
		end
	end

end

function attemptActivation()
	if not self.active then
		activate()
		local configBombDrop = { power = 0 }
		world.spawnProjectile("activeConshak", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
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
			status.clearPersistentEffects("nightarconshak")
			self.conshakTimer = 0
			world.sendEntityMessage(self.playerId,"removeBar","conshakBar")
		else
			attemptActivation()
		end
		return true
	else
		return false
	end
end

function activate()
	status.clearPersistentEffects("nightarconshak")
	self.active = true
end

function deactivate()
	if self.active then
		status.clearPersistentEffects("nightarconshak")
	end
	self.active = false
end
