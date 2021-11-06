require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/FRHelper.lua"

function init()
	self.weapon = Weapon:new()

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
	status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
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
									self.primaryAbility:startAttack()
									resetFistCombo()
								else
									self.primaryAbility:startAttack()
									advanceFistCombo(true)
								end
							end
						elseif activeItem.callOtherHandScript("triggerComboAttack", self.comboStep) then
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
	status.setStatusProperty(activeItem.hand().."ComboStep",nil)
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
		burstComboParticles(false)
		if comboStep == self.comboSteps then
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
		if (energyCost>0) then status.overConsumeResource("energy",energyCost) end
		self.comboStep = self.comboStep + 1
		status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
	end
	if doBurst then burstComboParticles(true) end
end

function burstComboParticles(wasLocal)
	local yarp=vec2.add(mcontroller.position(),vec2.rotate({self.weapon.aimDirection,0},self.weapon.aimAngle))
	yarp={world.xwrap(yarp[1]),yarp[2]}
	world.spawnProjectile("fuinvisibleprojectiletinyindicator",yarp,activeItem.ownerEntityId(),{0,0},true)
end

-- interrupt the combo for various reasons
function resetFistCombo()
	self.comboStep = 0
	status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
	self.comboTimer = nil
	return true
end

-- complete the combo, reset and trigger cooldown
function finishFistCombo()
	resetFistCombo()
	self.primaryAbility.cooldownTimer = self.comboCooldown
end
