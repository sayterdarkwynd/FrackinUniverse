require "/scripts/vec2.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=10--used by checkFood

function init()
	initCommonParameters()
end

function initCommonParameters()
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
	self.energyCostPerTick = config.getParameter("energyCostPerTick")
	self.bombTimer = 0
	self.xibulbTimer = 0
	self.xiBonus = status.stat("xiBonus")

	-- for status bar filling, below are required
	self.playerId = entity.id()
	self.maxXibulbValue = 350
	self.barName = "conshakBar"
	self.barColor = {150,77,250,125}
	self.timerRemoveXibulbBar = 0
end

function uninit()
	deactivate()
end

function checkStance()
	if (self.xibulbTimer < self.maxXibulbValue) then
		animator.setParticleEmitterActive("bulb", false)
	else
		animator.playSound("xibulbActivate")
		world.sendEntityMessage(self.playerId,"removeBar","xibulbBar")
	end
	if self.pressDown then
		 animator.setParticleEmitterActive("bulbStance", true)
		 animator.playSound("xibulbCharge")
	else
		animator.setParticleEmitterActive("bulbStance", false)
	end
	self.bombTimer = 10
end

--display madness bar
function displayBar()
	self.xibulbPercent = math.min(1.0,self.xibulbTimer / self.maxXibulbValue)

	if self.xibulbTimer > 300 then
		self.barColor = {71,255,212,222}
	elseif self.xibulbTimer > 250 then
		self.barColor = {79,217,255,199}
	elseif self.xibulbTimer > 150 then
		self.barColor = {193,217,11,170}
	elseif self.xibulbTimer > 100 then
		self.barColor = {179,135,11,125}
	elseif self.xibulbTimer > 50 then
		self.barColor = {147,71,14,90}
	else
		self.barColor = {18,86,32,125}
	end

	if (self.xibulbTimer > 0) then
		world.sendEntityMessage(self.playerId,"setBar","xibulbBar",self.xibulbPercent,self.barColor)
	else
		world.sendEntityMessage(self.playerId,"removeBar","xibulbBar")
	end
end

function update(args)
	 if (self.timerRemoveXibulbBar >=25) then
		 world.sendEntityMessage(entity.id(),"removeBar","xibulbBar")	 --clear ammo bar
		 self.timerRemoveXibulbBar = 0
	 else
		 self.timerRemoveXibulbBar = self.timerRemoveXibulbBar + 1
	 end
	if not self.specialLast and args.moves["special1"] then
		attemptActivation()
		animator.playSound("activate")
	end
	local tookHealth
	local tookEnergy
	self.specialLast = args.moves["special1"]
	self.pressDown = args.moves["down"]
	self.pressLeft = args.moves["left"]
	self.pressRight = args.moves["right"]
	self.pressUp = args.moves["up"]
	self.pressJump = args.moves["jump"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	-- make sure they are fed enough
	local foodValue=checkFood() or foodThreshold
	-- if fed, move to the effect
	if self.active then
		if self.bombTimer > 0 then
			self.bombTimer = math.max(0, self.bombTimer - args.dt)
		end
		--make sure we are only holding down
		if (self.pressDown) and not self.pressLeft and not self.pressRight and not self.pressUp and not self.pressJump then
			status.removeEphemeralEffect("wellfed")
			if (self.xibulbTimer < self.maxXibulbValue) then
				displayBar()
				--set food to reduce, but never to 0
				if (foodValue > foodThreshold) then
					status.modifyResource("food",-0.05)
					self.xibulbTimer = self.xibulbTimer + 1
				else
					tookEnergy=status.overConsumeResource("energy", (self.energyCostPerTick) or (self.energyCostPerSecond and (self.energyCostPerSecond*args.dt)) or 0.01,1)
					tookHealth=status.overConsumeResource("health", ((tookEnergy and 1) or 2)*0.035,1)
					if tookEnergy then-- or tookHealth then--challenge mode: make the timer only go up when you lose energy
						self.xibulbTimer = self.xibulbTimer + 1
					end
				end
			else
				displayBar()
			end
			animator.setParticleEmitterActive("bulbStance", true)
			if self.bombTimer == 0 then
				checkStance()
			end

			if (self.xibulbTimer >= self.maxXibulbValue) then
				self.rand = math.random(1,3)	-- how many Bulbs can we potentially spawn?
				self.onehundred = math.random(1,100)	 --chance to spawn rarer bulb types
				if (foodValue > foodThreshold) or tookEnergy then		--must have sufficient food, or drain energy to grow a seed.challenge race doesn't mean nonfunctional.
					animator.setParticleEmitterActive("bulbStance", false)
					animator.setParticleEmitterActive("bulb", true)
					--world.placeObject("xi_bulb",mcontroller.position(),1) -- doesnt seem to work with that position
					if self.onehundred == 100 then
						world.spawnItem("xi_bulb3", mcontroller.position(), 1)
					elseif self.onehundred > 80 then
						world.spawnItem("xi_bulb2", mcontroller.position(), self.rand)
					else
						world.spawnItem("xi_bulb", mcontroller.position(), self.rand)
					end
					local configBombDrop = { power = 0 }
					world.spawnProjectile("activeBulbCharged", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
					self.xibulbTimer = 0
				end
			end

		else
			animator.setParticleEmitterActive("bulbStance", false)
			animator.setParticleEmitterActive("bulb", false)
			self.xibulbTimer = 0
		end
		checkForceDeactivate(args.dt)
	end
end

function attemptActivation()
	if not self.active then
		activate()
		local configBombDrop = { power = 0 }
		world.spawnProjectile("activeBulb", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
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
			self.xibulbTimer = 0
		else
			attemptActivation()
		end
		return true
	else
		return false
	end
end

function activate()
	status.setPersistentEffects("bulbEffect", {"fugenerictechdummyholddown"})
	self.active = true
end

function deactivate()
	status.setPersistentEffects("bulbEffect", {})
	self.active = false
end