require("/scripts/FRHelper.lua")
require "/scripts/status.lua" --for damage listener
require "/items/active/tagCaching.lua"
require "/stats/effects/fu_statusUtil.lua"
require "/scripts/util.lua"

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

function MeleeCombo:init()
	self.baseStanceData=copy(self.stances)
	self.stances=self:regurgitateStances(copy(self.baseStanceData),self.fireTime)
	self.comboStep = 1
	status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)

	fuLoadSwooshData(self)
	self.energyUsage = self.energyUsage or 0

	self:computeDamageAndCooldowns()

	self.weapon:setStance(self.stances.idle)

	self.edgeTriggerTimer = 0
	self.flashTimer = 0
	self.cooldownTimer = self.cooldowns[1]

	self.animKeyPrefix = self.animKeyPrefix or ""

	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end

	-- **************************************************
	-- FR EFFECTS
	-- **************************************************
	self.species = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
	self.foodValue=(status.isResource("food") and status.resource("food")) or 60
	attackSpeedUp = status.stat("attackSpeedUp") -- base attackSpeed. This acts as the timer between *combos* , not individual attacks
	--only use tag caching in meleecombo for energy costs.
	tagCaching.update()
end
-- **************************************************

-- Ticks on every update regardless of whether this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
	if self.fireTime~=self.recordedFireTime then
		self.stances=self:regurgitateStances(copy(self.baseStanceData),self.fireTime)
	end
	tagCaching.update()
	if self.delayLoad then
		fuLoadSwooshData(self)
	end
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	setupHelper(self, "meleecombo-fire")
	attackSpeedUp = status.stat("attackSpeedUp")

	if self.cooldownTimer > 0 then
		self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
		if self.cooldownTimer == 0 then
			self:readyFlash()
		end
	end

	if self.flashTimer > 0 then
		self.flashTimer = math.max(0, self.flashTimer - self.dt)
		if self.flashTimer == 0 then
			animator.setGlobalTag("bladeDirectives", "")
		end
	end

	self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
	if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
		self.edgeTriggerTimer = self.edgeTriggerGrace
	end
	if (status.resourceLocked("energy")) or (status.resource("energy") <= 1) then
		self.edgeTriggerTimer = 0.0
	end
	self.lastFireMode = fireMode

	if not self.weapon.currentAbility and self:shouldActivate() then
		self:setState(self.windup)
	end
end

function MeleeCombo:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function MeleeCombo:aimVector()	-- fires straight
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle )
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function MeleeCombo:aimVectorRand() -- fires wherever it wants
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end
-- *****************************************

-- State: windup

-- *** FU ------------------------------------
-- FU adds an encapsulating check in Windup, for energy. If there is no energy to consume, the weapon cannot combo
function MeleeCombo:windup()
	self.energyMax = math.max(status.resourceMax("energy"),0) -- due to weather and other cases it is possible to have a maximum of under 0.
	--root.itemHasTag(world.entityHandItem(activeItem.ownerEntityId(),"primary"),"melee")
	if tagCaching.primaryTagCache["melee"] and tagCaching.altTagCache["melee"] then
		self.energyTotal = (self.energyMax * 0.025)
	else
		self.energyTotal = (self.energyMax * 0.01)
	end
	if (status.resource("energy") <= 1) or (not status.consumeResource("energy",self.energyTotal)) then
		self.comboStep = 1
		status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
		status.setStatusProperty(activeItem.hand().."Firing",true)
	else
		self.comboStep=self.comboStep or 1
		status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
		status.setStatusProperty(activeItem.hand().."Firing",true)
	end

	local stance = self.stances["windup"..self.comboStep]

	self.weapon:setStance(stance)
	self.edgeTriggerTimer = 0

	if stance.hold then
		while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
			coroutine.yield()
		end
	else
		util.wait(stance.duration)
	end

	if self.energyUsage then
		status.overConsumeResource("energy", self.energyUsage)
	end

	if self.stances["preslash"..self.comboStep] then
		self:setState(self.preslash)
	else
		self:setState(self.fire)
	end
end

-- State: wait
-- waiting for next combo input
function MeleeCombo:wait()
	local stance = self.stances["wait"..(self.comboStep - 1)] or self.stances["wait"] or self.stances["wait".."0"] or self.stances["wait".."1"] or self.stances["wait".."2"] or self.stances["wait".."3"]

	if stance then
		self.weapon:setStance(stance)
	else
		stance={}
		stance.duration=0.12
	end

	util.wait(stance.duration, function()
		if self:shouldActivate() then
			self:setState(self.windup)
			return
		end
	end)

	self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
	-- *** FR
	self.cooldownTimer = math.max(0, self.cooldownTimer * attackSpeedUp)
	if status.resource("energy") < 1 then
		self.cooldownTimer = self.cooldownTimer + 0.1
	end
	self.comboStep = 1
	status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
	status.setStatusProperty(activeItem.hand().."Firing",false)
end

-- State: preslash
-- brief frame in between windup and fire
function MeleeCombo:preslash()
	local stance = self.stances["preslash"..self.comboStep]

	self.weapon:setStance(stance)
	self.weapon:updateAim()

	util.wait(stance.duration)

	self:setState(self.fire)
end

-- ***********************************************************************************************************
-- FR SPECIALS	Functions for projectile spawning
-- ***********************************************************************************************************
function MeleeCombo:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function MeleeCombo:aimVector()	-- fires straight
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle )
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function MeleeCombo:aimVectorRand() -- fires wherever it wants
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end
-- ***********************************************************************************************************
-- END FR SPECIALS
-- ***********************************************************************************************************

-- State: fire
function MeleeCombo:fire()
	local stance = self.stances["fire"..self.comboStep]

	self.weapon:setStance(stance)
	self.weapon:updateAim()

	if self.helper then
		self.helper:runScripts("meleecombo-fire", self)
	end

	local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
	local swooshCheckA=self.swooshList[animStateKey] and animStateKey
	local swooshCheckB=self.swooshList["fire"] and "fire"
	if swooshCheckA or swooshCheckB then
		animator.setAnimationState("swoosh", swooshCheckA or swooshCheckB)
	end

	--animator.setAnimationState("swoosh", animStateKey)
	if animator.hasSound(animStateKey) then
		animator.playSound(animStateKey)
	elseif animator.hasSound("fire") then
		animator.playSound("fire")
	end

	local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
	animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
	animator.burstParticleEmitter(swooshKey)

	--*************************************
	-- FU/FR ABILITIES
	--*************************************
	if not self.helper and self.species:succeeded() then
		self.helper = FRHelper:new(self.species:result(), world.entityGender(activeItem.ownerEntityId()))
		self.helper:loadWeaponScripts("meleecombo-fire")
	end
	if self.helper then
		self.helper:runScripts("meleecombo-fire", self)
	end
	--**************************************

	util.wait(stance.duration, function()
		local damageArea = partDamageArea("swoosh")
		self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
	end)

	if self.comboStep < self.comboSteps then
		self.comboStep = self.comboStep + 1
		status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
		self:setState(self.wait)
	else
		self.cooldownTimer = self.cooldowns[self.comboStep]
		-- **** FR cooldown adjustment
		self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep] * ( 1 - attackSpeedUp))
		-- *****
		self.comboStep = 1
		status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
	end
end

function MeleeCombo:shouldActivate()
	if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
		if self.comboStep and (self.comboStep > 1) then
			return self.edgeTriggerTimer > 0
		else
			return self.fireMode == (self.activatingFireMode or self.abilitySlot)
		end
	end
end

function MeleeCombo:readyFlash()
	animator.setGlobalTag("bladeDirectives", self.flashDirectives)
	self.flashTimer = self.flashTime
end

function MeleeCombo:computeDamageAndCooldowns()
	local attackTimes = {}
	for i = 1, self.comboSteps do
		local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
		if self.stances["preslash"..i] then
				attackTime = attackTime + self.stances["preslash"..i].duration
		end
		table.insert(attackTimes, attackTime)
	end

	self.cooldowns = {}
	local totalAttackTime = 0
	local totalDamageFactor = 0
	for i, attackTime in ipairs(attackTimes) do
		self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
		self.stepDamageConfig[i].timeoutGroup = "primary"..i

		local damageFactor = self.stepDamageConfig[i].baseDamageFactor
		self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

		totalAttackTime = totalAttackTime + attackTime
		totalDamageFactor = totalDamageFactor + damageFactor

		local targetTime = totalDamageFactor * self.fireTime
		local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
		table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
	end
end

function MeleeCombo:uninit()
	self.comboStep = nil
	status.setStatusProperty(activeItem.hand().."ComboStep",self.comboStep)
	status.setStatusProperty(activeItem.hand().."Firing",nil)

	if self.helper then
		self.helper:clearPersistent()
	end

	self.weapon:setDamage()
end

function fuLoadSwooshData(self)
	self.swooshList={}
	local animationData=config.getParameter("animation")
	if type(animationData)=="string" and animationData:sub(1,1)=="/" then
		animationData=root.assetJson(animationData)
	elseif type(animationData)=="string" then
		if world.entityType(activeItem.ownerEntityId()) then
			local buffer=world.entityHandItem(activeItem.ownerEntityId(),activeItem.hand())
			buffer=root.itemConfig(buffer).directory..animationData
			animationData=root.assetJson(buffer)
		else
			self.delayLoad=true
			return
		end
	else
		animationData=nil
	end
	if animationData and animationData.animatedParts and animationData.animatedParts.stateTypes and animationData.animatedParts.stateTypes.swoosh and animationData.animatedParts.stateTypes.swoosh.states then
		for swoosh,_ in pairs(animationData.animatedParts.stateTypes.swoosh.states) do
			self.swooshList[swoosh]=true
		end
	end
	local animationCustom=config.getParameter("animationCustom")
	if animationCustom and animationCustom.animatedParts and animationCustom.animatedParts.stateTypes and animationCustom.animatedParts.stateTypes.swoosh and animationCustom.animatedParts.stateTypes.swoosh.states then
		for swooshkey,_ in pairs(animationCustom.animatedParts.stateTypes.swoosh.states) do
			self.swooshList[swooshkey]=true
		end
	end
	self.delayLoad=false
end

function MeleeCombo:regurgitateStances(stances,fireTime)
	--sb.logInfo("%s",stances)
	local buffer={}
	for stanceName,stanceData in pairs(stances) do
		if stanceData.duration then stanceData.duration=stanceData.duration * fireTime end
		buffer[stanceName]=stanceData
	end
	--sb.logInfo("%s",buffer)
	self.recordedFireTime=fireTime
	return(buffer)
end
