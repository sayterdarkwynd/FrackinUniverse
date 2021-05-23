require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/FRHelper.lua"

function init()
	self.weapon = Weapon:new()

	local particleParams=config.getParameter("comboParticleParams")
	if not particleParams then
		local animation=config.getParameter("comboParticleAnimation") or "/animations/sparkles/sparkleloop2.animation"
		local comboParticleSpecification=config.getParameter("comboParticleSpecification") or {
			type="animated",animation=animation,position={0,0},layer="back",initialVelocity={0,0},finalVelocity={0,-1},approach={0,50},fade=0.5,destructionAction="shrink",destructionTime=0.5,
			size=0.4,timeToLive=0.5,fullbright=true,
			--variance={initialVelocity={1,1},position={1,1}}
			variance={initialVelocity={1,1},finalVelocity={1,1},position={1,1}}
		}
		local body={action="particle",specification=comboParticleSpecification,time=0.45}--{action="particle",specification="astraltearsparkle2",time=0.45}
		body["repeat"]=true--this is a pain, errors if done like {repeat=true}
		particleParams={{action = "loop",count = 5,body = {body}}}
	end

	self.comboParticleProjectileParams={}
	self.comboParticleProjectileParams.actionOnReap=particleParams

	self.weapon:addTransformationGroup("weapon", {0,0}, 0)

	self.primaryAbility = getPrimaryAbility()
	self.weapon:addAbility(self.primaryAbility)

	local comboFinisherConfig = config.getParameter("comboFinisher")
	self.comboFinisher = getAbility("comboFinisher", comboFinisherConfig)
	self.weapon:addAbility(self.comboFinisher)

	self.weapon:init()

	self.needsEdgeTrigger = config.getParameter("needsEdgeTrigger", false)
	self.edgeTriggerGrace = config.getParameter("edgeTriggerGrace", 0)
	self.edgeTriggerTimer = 0

	self.comboStep = 0
	self.comboSteps = config.getParameter("comboSteps")
	self.comboTiming = config.getParameter("comboTiming")
	self.comboCooldown = config.getParameter("comboCooldown")

	self.weapon.freezeLimit = config.getParameter("freezeLimit", 2)
	self.weapon.freezesLeft = self.weapon.freezeLimit

	updateHand()
end

function update(dt, fireMode, shiftHeld)
	--*************************************
	-- FU/FR ADDONS
	setupHelper(self, {"fist-update", "fist-precombo", "fist-combo", "fist-postcombo"})

	if self.helper then
		self.helper:clearPersistent()
		self.helper:runScripts("fist-update", self, dt, fireMode, shiftHeld)	-- effect on update
	end
	--*************************************

	if mcontroller.onGround() then
		self.weapon.freezesLeft = self.weapon.freezeLimit
	end

	if self.comboStep > 0 then
		self.comboTimer = self.comboTimer + dt
		if self.comboTimer > self.comboTiming[2] then
			resetFistCombo()
		end
	end

	self.fistMastery = 1 + status.stat("fistMastery")
	self.fistMasteryHalved = ((self.fistMastery -1) / 2) + 1
	world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","fistbonus")
	status.setPersistentEffects("fistbonus",{
		{stat="stunChance",amount= 2 * self.fistMastery },
		{stat="critChance",amount= 2 * self.fistMastery },
		{stat="powerMultiplier",effectiveMultiplier= self.fistMasteryHalved }
	})	


	self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
	if self.lastFireMode ~= "primary" and fireMode == "primary" then
		self.edgeTriggerTimer = self.edgeTriggerGrace
	end
	self.lastFireMode = fireMode

	--*************************************
	-- FR pre-combo script location
	--*************************************
	if self.helper then
		self.state = "precombo"
		self.helper:runScripts("fist-precombo", self, dt, fireMode, shiftHeld)	-- effect before combo
	end
	--*************************************

	if fireMode == "primary" then
		if (not self.needsEdgeTrigger) or (self.edgeTriggerTimer > 0) then
			if self.comboStep > 0 then

				--*************************************
				-- FR "combo based" fist weapon bonus
				--*************************************
				if self.helper then
					self.state = "combo"
					self.helper:runScripts("fist-combo", self, dt, fireMode, shiftHeld)	-- effect during combo
				end
				--*************************************

				if self.comboTimer >= self.comboTiming[1] then
					if shiftHeld then
						if self.primaryAbility:canStartAttack() then
							local energyCost=status.resourceMax("energy")*0.03
							if (self.comboStep == self.comboSteps) or ((energyCost>0) and status.overConsumeResource("energy",energyCost)) then
								self.comboFinisher:startAttack()
								resetFistCombo()
							end
						end
					else
						if self.comboStep % 2 == 0 then
							if self.primaryAbility:canStartAttack() then
								if self.comboStep == self.comboSteps then
									-- sb.logInfo("[%s] %s fist starting a combo finisher", os.clock(), activeItem.hand())
									--self.comboFinisher:startAttack()
									self.primaryAbility:startAttack()
									resetFistCombo()
								else
									self.primaryAbility:startAttack()
									-- sb.logInfo("[%s] %s fist continued the combo", os.clock(), activeItem.hand())
									advanceFistCombo(true)
								end
							end
						elseif activeItem.callOtherHandScript("triggerComboAttack", self.comboStep) then
							-- sb.logInfo("[%s] %s fist triggered opposing attack", os.clock(), activeItem.hand())
							advanceFistCombo()
						end
					end
				end
			else
				if self.primaryAbility:canStartAttack() then
					if shiftHeld then
						if self.primaryAbility:canStartAttack() then
							local energyCost=status.resourceMax("energy")*0.15
							if (energyCost>0) and status.overConsumeResource("energy",energyCost) then
								resetFistCombo()
								self.comboFinisher:startAttack()
							end
						end
					else
						self.primaryAbility:startAttack()
						if activeItem.callOtherHandScript("resetFistCombo") then
							-- sb.logInfo("[%s] %s fist started a combo", os.clock(), activeItem.hand())
							advanceFistCombo()
						end
					end
				end
			end
		else
			--non-combo hits reset the chain and cost energy. allows attack spam.
			if self.primaryAbility:canStartAttack() then
				local energyCost=status.resourceMax("energy")*0.03
				if (energyCost>0) and status.overConsumeResource("energy",energyCost) then
					resetFistCombo()
					activeItem.callOtherHandScript("resetFistCombo")
					self.primaryAbility:startAttack()
				end
			end
		end
	end

	--*************************************
	-- FR post-combo script location
	--*************************************
	if self.helper then
		self.state = "postcombo"
		self.helper:runScripts("fist-postcombo", self, dt, fireMode, shiftHeld)	-- effect after combo
	end
	--*************************************
	self.weapon:update(dt, fireMode, shiftHeld)
	updateHand()
end

function uninit()
	--*************************************
	-- FU/FR ADDONS
	if self.helper then
		self.helper:clearPersistent()
	end
	--*************************************
	resetFistCombo()
	if unloaded then
		activeItem.callOtherHandScript("resetFistCombo")
	end
	self.weapon:uninit()
end

-- update which image we're using and keep the weapon visually in front of the hand
function updateHand()
	local isFrontHand = self.weapon:isFrontHand()
	animator.setGlobalTag("hand", isFrontHand and "front" or "back")
	animator.resetTransformationGroup("swoosh")
	animator.scaleTransformationGroup("swoosh", isFrontHand and {1, 1} or {1, -1})
	activeItem.setOutsideOfHand(isFrontHand)
end

-- called remotely to attempt to perform a combo-continuing attack
function triggerComboAttack(comboStep)
	if self.primaryAbility:canStartAttack() then
		-- sb.logInfo("%s fist received combo trigger for combostep %s", activeItem.hand(), comboStep)
		burstComboParticles(false)
		if comboStep == self.comboSteps then
			--self.comboFinisher:startAttack()
			self.primaryAbility:startAttack()
		else
			self.primaryAbility:startAttack()
		end
		return true
	else
		return false
	end
end

-- advance to the next step of the combo
function advanceFistCombo(doBurst)
	self.comboTimer = 0
	if self.comboStep < self.comboSteps then
		local energyCost=status.resourceMax("energy")*0.005
		--if (energyCost>0) and status.overConsumeResource("energy",energyCost) then
		if (energyCost>0) then status.overConsumeResource("energy",energyCost) end
		-- sb.logInfo("%s fist advancing combo from step %s to %s", activeItem.hand(), self.comboStep, self.comboStep + 1)
		self.comboStep = self.comboStep + 1
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","fistweaponcombobonus")
		status.setPersistentEffects("fistweaponcombobonus",{
			{stat="stunChance",amount=self.comboStep*4},
			{stat="critChance",amount=self.comboStep*1},
			{stat="protection",amount=self.comboStep*1}
		})	
		--end
		--animator.burstParticleEmitter("flames")--stop using. compatibility. ERM seems a common culprit of "use base scripts but custom anims file"
		--burstComboParticles()--better idea: move it to the part that handles picking a hand.
	end
	if doBurst then burstComboParticles(true) end
end

function burstComboParticles(wasLocal)
	--sb.logInfo("wasLocal %s",wasLocal)
	if self.comboParticleProjectileParams then
		local yarp=vec2.add(mcontroller.position(),vec2.rotate({self.weapon.aimDirection,0},self.weapon.aimAngle))
		yarp={world.xwrap(yarp[1]),yarp[2]}
		world.spawnProjectile("fuinvisibleprojectiletinyindicator",yarp,activeItem.ownerEntityId(),{0,0},true,self.comboParticleProjectileParams)
	end
end

-- interrupt the combo for various reasons
function resetFistCombo()
	-- sb.logInfo("%s fist resetting combo from step %s to 0", activeItem.hand(), self.comboStep)
	self.comboStep = 0
	self.comboTimer = nil
	status.setPersistentEffects("fistweaponcombobonus",{})
	status.setPersistentEffects("fistbonus",{})
	return true
end

-- complete the combo, reset and trigger cooldown
function finishFistCombo()
	resetFistCombo()
	self.primaryAbility.cooldownTimer = self.comboCooldown
end
