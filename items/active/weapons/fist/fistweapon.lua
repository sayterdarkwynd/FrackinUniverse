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
							self.comboFinisher:startAttack()
							resetFistCombo()
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
									advanceFistCombo()
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
							resetFistCombo()
							self.comboFinisher:startAttack()
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
				if status.overConsumeResource("energy",status.resourceMax("energy")*0.01) then
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
function advanceFistCombo(reset)
	self.comboTimer = 0
	if self.comboStep < self.comboSteps then
		-- sb.logInfo("%s fist advancing combo from step %s to %s", activeItem.hand(), self.comboStep, self.comboStep + 1)
		self.comboStep = self.comboStep + 1
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUArmorSetBonus","fistweaponcombobonus")
		status.setPersistentEffects("fistweaponcombobonus",{
			{stat="stunChance",amount=self.comboStep*4},
			{stat="critChance",amount=self.comboStep*1}
		})
	end
end

-- interrupt the combo for various reasons
function resetFistCombo()
	-- sb.logInfo("%s fist resetting combo from step %s to 0", activeItem.hand(), self.comboStep)
	self.comboStep = 0
	self.comboTimer = nil
	status.setPersistentEffects("fistweaponcombobonus",{})
	return true
end

-- complete the combo, reset and trigger cooldown
function finishFistCombo()
	resetFistCombo()
	self.primaryAbility.cooldownTimer = self.comboCooldown
end
