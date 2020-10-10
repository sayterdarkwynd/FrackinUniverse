require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/melee/meleeslash.lua"
require("/scripts/FRHelper.lua")

-- Axe primary attack
-- Extends default melee attack and overrides windup and fire
AxeCleave = MeleeSlash:new()

function AxeCleave:init()
	self.stances.windup.duration = self.fireTime - self.stances.fire.duration

	attackSpeedUp = 0 -- base attackSpeed bonus
		self.hitsListener = damageListener("inflictedHits", checkDamage)	--listen for damage
		self.damageListener = damageListener("inflictedDamage", checkDamage)	--listen for damage
		self.killListener = damageListener("Kill", checkDamage)	--listen for kills

	MeleeSlash.init(self)
	self:setupInterpolation()

	self.inflictedHitCounter = 0
	self.inflictedKills = 0
		status.clearPersistentEffects("listenerBonus")
end

function checkDamage(notifications)
	for _,notification in pairs(notifications) do
		--check for individual hits
		if notification.sourceEntityId == entity.id() or notification.targetEntityId == entity.id() then
			if not status.resourcePositive("health") then --count total kills
				notification.hitType = "Kill"
			end
			local hitType = notification.hitType
			--sb.logInfo(hitType)

				--kill computation
			if notification.hitType == "Kill" or notification.hitType == "kill" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then
				--each consequtive kill in rapid succession increases damage for weapons in this grouping. Per kill. Resets automatically very soon after to prevent abuse.
				if not self.inflictedKills then self.inflictedKills = 0 end --set base to 0. This means *second* kill provides the first bonus
				self.inflictedKills = self.inflictedKills + 1
				if self.inflictedKills > 500 then
					--status.clearPersistentEffects("listenerBonus2")
					self.inflictedKills = 500
				else
					status.setPersistentEffects("listenerBonus2", {
						{stat = "powerMultiplier", effectiveMultiplier = 1 + self.inflictedKills/100}
					})
				end

				if (status.resource("health") / status.stat("maxHealth")) < 0.2 then -- if health falls below 20% cancel the bonus
					status.clearPersistentEffects("listenerBonus2")
				end
				--sb.logInfo("total axe kills : "..self.inflictedKills)
			end

			--hit computation
			if notification.hitType == "Hit" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then
			 		--check hit types and calculate any that apply
				if not self.inflictedHitCounter then self.inflictedHitCounter = 1 end
			 		self.inflictedHitCounter = self.inflictedHitCounter + 1
					--sb.logInfo("axe hit counter : "..self.inflictedHitCounter)
				if self.inflictedHitCounter > 5 then
					status.clearPersistentEffects("listenerBonus")
					self.inflictedHitCounter = 0
				else
		 			status.setPersistentEffects("listenerBonus", {
		 				{stat = "critChance", amount = self.inflictedHitCounter * 3 }
		 			})
				end
			end
			return
		end
	end
end

function AxeCleave:windup(windupProgress)
	-- reset special count values
	--[[if self.inflictedHitCounter > 5 then
	end
	if self.inflictedKills > 20 then
	end]]

	self.energyTotal = math.max(status.stat("maxEnergy") * 0.07,0) -- due to weather and other cases it is possible to have a maximum of under 0.
	if (status.resource("energy") <= 1) or not (status.consumeResource("energy",math.min((status.resource("energy")-1), self.energyTotal))) then
		cancelEffects()
		self.lowEnergy=true
	else
		self.lowEnergy=false
	end
	
	--*************************************
	-- FU/FR ADDONS
	setupHelper(self, "axecleave-fire")
	--**************************************

	self.weapon:setStance(self.stances.windup)

	local windupProgress = windupProgress or 0
	local bounceProgress = 0
	while self.fireMode == "primary" and (self.allowHold ~= false or windupProgress < 1) do
		if windupProgress < 1 then
			windupProgress = math.min(1, windupProgress + (self.dt / self.stances.windup.duration))
			self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
		else
			bounceProgress = math.min(1, bounceProgress + (self.dt / self.stances.windup.bounceTime))
			self.weapon.relativeWeaponRotation = self:bounceWeaponAngle(bounceProgress)
		end
		coroutine.yield()
	end

	if windupProgress >= 1.0 then
		if self.stances.preslash then
			self:setState(self.preslash)
		else
			self:setState(self.fire)
		end
	else
		self:setState(self.winddown, windupProgress)
	end
end

function AxeCleave:winddown(windupProgress)
	self.weapon:setStance(self.stances.windup)

	while windupProgress > 0 do
		if self.fireMode == "primary" then
			self:setState(self.windup, windupProgress)
			return true
		end

		windupProgress = math.max(0, windupProgress - (self.dt / self.stances.windup.duration))
		self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
		coroutine.yield()
	end
end

function AxeCleave:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()
	self.hitsListener:update()
	self.damageListener:update()
	self.killListener:update()
	animator.setAnimationState("swoosh", "fire")
	if animator.hasSound("fire") then
		animator.playSound("fire")
	end
	animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

	-- ******************* FR ADDONS FOR HAMMER SWINGS
	if self.helper then
		self.helper:runScripts("axecleave-fire", self)
		end
	-- ***********************************************

	util.wait(self.stances.fire.duration, function()
		local damageArea = partDamageArea("swoosh")
		local damageConfigCopy=copy(self.damageConfig)
		if self.lowEnergy then
			damageConfigCopy.baseDamage=damageConfigCopy.baseDamage*0.75
		end
		self.weapon:setDamage(damageConfigCopy, damageArea, self.fireTime)
	end)


	self.cooldownTimer = self:cooldownTime()
end

function AxeCleave:setupInterpolation()
	for i, v in ipairs(self.stances.windup.bounceWeaponAngle) do
		v[2] = interp[v[2]]
	end
	for i, v in ipairs(self.stances.windup.weaponAngle) do
		v[2] = interp[v[2]]
	end
	for i, v in ipairs(self.stances.windup.armAngle) do
		v[2] = interp[v[2]]
	end
end

function AxeCleave:bounceWeaponAngle(ratio)
	return util.toRadians(interp.ranges(ratio, self.stances.windup.bounceWeaponAngle))
end

function AxeCleave:windupAngle(ratio)
	local weaponRotation = interp.ranges(ratio, self.stances.windup.weaponAngle)
	local armRotation = interp.ranges(ratio, self.stances.windup.armAngle)

	return util.toRadians(weaponRotation), util.toRadians(armRotation)
end

function AxeCleave:uninit()
	if self.helper then
		self.helper:clearPersistent()
	end
	self.blockCount = 0
end

function cancelEffects()
	status.clearPersistentEffects("longswordbonus")
	status.clearPersistentEffects("macebonus")
	status.clearPersistentEffects("katanabonus")
	status.clearPersistentEffects("rapierbonus")
	status.clearPersistentEffects("shortspearbonus")
	status.clearPersistentEffects("daggerbonus")
	status.clearPersistentEffects("scythebonus")
	status.clearPersistentEffects("axebonus")
	status.clearPersistentEffects("hammerbonus")
	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
	status.clearPersistentEffects("listenerBonus")
	status.clearPersistentEffects("masteryBonus")
	self.rapierTimerBonus = 0
	self.inflictedHitCounter = 0
end