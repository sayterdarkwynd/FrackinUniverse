require("/scripts/FRHelper.lua")
require "/scripts/status.lua" --for damage listener

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

function MeleeCombo:init()
	status.clearPersistentEffects("combobonusdmg")
	self.comboStep = 1

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
		calculateMasteries() --determine any active Masteries
	end

	--[[never actually called, these variables (primaryItem,altItem) are defined BELOW this.
	self.energyMax = status.resourceMax("energy") -- due to weather and other cases it is possible to have a maximum of under 1.
	if (primaryItem and root.itemHasTag(primaryItem, "melee")) and (altItem and root.itemHasTag(altItem, "melee")) then
		self.energyTotal = (self.energyMax * 0.025)
	else
		self.energyTotal = (self.energyMax * 0.01)
	end]]

	-- **************************************************
	-- FU EFFECTS

	primaryItem = world.entityHandItem(entity.id(), "primary")	--check what they have in hand
	altItem = world.entityHandItem(entity.id(), "alt")
	if primaryTagCacheItem~=primaryItem then
		primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
		primaryTagCacheItem=primaryItem
	elseif not primaryItem then
		primaryTagCache={}
	end
	if altTagCacheItem~=altItem then
		altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
		altTagCacheItem=altItem
	elseif not altItem then
		altTagCache={}
	end

	self.rapierTimerBonus = 0
	self.effectTimer = 0

	self.hitsListener = damageListener("inflictedHits", checkDamage)	--listen for damage
	self.damageListener = damageListener("inflictedDamage", checkDamage)	--listen for damage
	self.killListener = damageListener("Kill", checkDamage)	--listen for kills
	--self.hitsListener = damageListener("damageTaken", checkDamage)	--listen for kills
	-- **************************************************
	-- FR EFFECTS
	-- **************************************************
	self.species = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
	self.foodValue=(status.isResource("food") and status.resource("food")) or 60
	attackSpeedUp = 0 -- base attackSpeed. This acts as the timer between *combos* , not individual attacks
	self.meleeCount=self.meleeCount or 0
	self.meleeCount2=self.meleeCount2 or 0
end
-- **************************************************

function calculateMasteries() -- doesn't work inside certain functions, such as MeleeCombo:Update
	self.shortswordMastery = 1 + status.stat("shortswordMastery")
	self.longswordMastery = 1 + status.stat("longswordMastery")
	self.rapierMastery = 1 + status.stat("rapierMastery")
	self.katanaMastery = 1 + status.stat("katanaMastery")
	self.daggerMastery = 1 + status.stat("daggerMastery")
	self.broadswordMastery = 1 + status.stat("broadswordMastery")
	self.quarterstaffMastery = 1 + status.stat("quarterstaffMastery")
	self.maceMastery = 1 + status.stat("maceMastery")
	self.shortspearMastery = 1 + status.stat("shortspearMastery")
	self.hammerMastery = 1 + status.stat("hammerMastery")
	self.axeMastery = 1 + status.stat("axeMastery")
	self.spearMastery = 1 + status.stat("spearMastery")
	self.scytheMastery = 1 + status.stat("scytheMastery")
end

function checkDamage(notifications)
	if primaryTagCacheItem~=primaryItem then
		primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
		primaryTagCacheItem=primaryItem
	elseif not primaryItem then
		primaryTagCache={}
	end
	if altTagCacheItem~=altItem then
		altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
		altTagCacheItem=altItem
	elseif not altItem then
		altTagCache={}
	end

	for _,notification in pairs(notifications) do

		-- defense
		--if notification.targetEntityId then
		--	if notification.hitType == "ShieldHit" or notification.hitType == "Knockback" then
		--			sb.logInfo("i blocked with a shield")
		--	end
		--	if notification.damageType == "Damage" then
		--		sb.logInfo("i was hit")
		--		--reset special counters when hit
		--		self.rapierTimerBonus = 0
		--		self.inflictedHitCounter = 0
		--	end
		--end
		--check for individual combo hits
		if (notification.sourceEntityId == entity.id()) or (notification.targetEntityId == entity.id()) then
			if not status.resourcePositive("health") then --count total kills
				notification.hitType = "kill"
			end
			local hitType = notification.hitType
			--sb.logInfo(hitType)

			--kill computation
			local noticeEntType=world.entityType(notification.targetEntityId)
			local listenerbonus={}
			if string.lower(notification.hitType) == "kill" and ((noticeEntType == "monster") or (noticeEntType == "npc")) and world.entityCanDamage(notification.targetEntityId, entity.id()) then
				--each consequtive kill in rapid succession increases damage for weapons in this grouping. Per kill. Resets automatically very soon after to prevent abuse.

				if primaryTagCache["longsword"] or altTagCache["longsword"] or primaryTagCache["dagger"] or altTagCache["dagger"] then
					self.longswordMastery = 1 + status.stat("longswordMastery")
					self.daggerMastery = 1 + status.stat("daggerMastery")
					--add special coding to handle mixed weapons, rather than just going by longsword mastery
					local masteryValue=1.0
					local masteryCalcBuffer=0.0
					local masteryCounts=0

					if (primaryTagCache["longsword"]) or (altTagCache["longsword"]) then
						masteryCalcBuffer=masteryCalcBuffer+(self.longswordMastery-1.0)
						masteryCounts=masteryCounts+1
					end
					if (primaryTagCache["dagger"]) or (altTagCache["dagger"]) then
						masteryCalcBuffer=masteryCalcBuffer+(self.longswordMastery-1.0)
						masteryCounts=masteryCounts+1
					end

					if masteryCounts>0 then
						masteryCalcBuffer=masteryCalcBuffer/masteryCounts
						masteryValue=masteryValue+masteryCalcBuffer
					end

					if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end
					self.totalKillsValue = 1 + self.inflictedHitCounter/50
					table.insert(listenerbonus,{stat = "powerMultiplier", effectiveMultiplier = self.totalKillsValue * masteryValue})
				end

				-- broadswords increase defense on consecutive kills
				if (primaryTagCache["broadsword"]) or (altTagCache["broadsword"]) then
					self.broadswordMastery = 1 + status.stat("broadswordMastery")
					if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end
					self.totalKillsValue = math.min(1.35,(1 + self.inflictedHitCounter/20) * self.broadswordMastery)
					table.insert(listenerbonus,{stat = "protection", effectiveMultiplier = self.totalKillsValue })
					table.insert(listenerbonus,{stat = "grit", amount = (self.broadswordMastery-1.0) * 0.5})	-- secret bonus from Broadsword Mastery
				end
			end

			--hit computation
			if string.lower(notification.hitType) == "hit" and ((noticeEntType == "monster") or (noticeEntType == "npc")) and world.entityCanDamage(notification.targetEntityId, entity.id()) then
				--check hit types and calculate any that apply
				--if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end --moved to line below.
				self.inflictedHitCounter = (self.inflictedHitCounter or 0) + 1
				if self.inflictedHitCounter > 0 then
					if (primaryTagCache["katana"]) or (altTagCache["katana"]) then
						--each hit with a combo using a katana increases its knockback resistance
						table.insert(listenerbonus,{stat = "grit", amount = self.inflictedHitCounter/20.0})
					end
					if (primaryTagCache["shortsword"]) or (altTagCache["shortsword"]) then
						--each hit with a combo using a shortsword increases its crit damage
						table.insert(listenerbonus,{stat = "critDamage", amount = ((self.inflictedHitCounter/100) * 5)})
					end
					if (primaryTagCache["quarterstaff"]) or (altTagCache["quarterstaff"]) then
						--each hit with a combo using a quarterstaff increases its defense output
						--cap the bonus so they cant spin it forever
						self.finalBonus = self.inflictedHitCounter / 5
						table.insert(listenerbonus,{stat = "protection", effectiveMultiplier = math.min(1.5,1 + self.finalBonus)})
					end
					if (primaryTagCache["mace"]) or (altTagCache["mace"]) then
						--each hit with a combo using a mace increases its stun chance
						table.insert(listenerbonus,{stat = "stunChance", amount = self.inflictedHitCounter*2})
					end
				end
			end

			status.setPersistentEffects("listenerbonus", listenerbonus)
			return
		end
	end
end

-- Ticks on every update regardless of whether this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
	if self.delayLoad then
		fuLoadSwooshData(self)
	end
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	setupHelper(self, "meleecombo-fire")
	self.hitsListener:update()
	self.damageListener:update()
	self.killListener:update()
	if not attackSpeedUp then
		attackSpeedUp = 0
	else
		attackSpeedUp = status.stat("attackSpeedUp")
	end

	-- *****************************************Passive Weapon Masteries and Item Tag Caching ***************************
	-- ******************************************************************************************************************
	-- only apply the following if the character has a Mastery trait. These are ONLY obtained from specific types of gear or loot.
	-- this section also primes the code for later blocks. all loading of mastery variables should be done here. this is also one of two places where item tag caching occurs.
	-- this is also a good place to put simple, nonconditional mastery bonuses.

	--cache tag data for use
	if primaryTagCacheItem~=primaryItem then
		primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
		primaryTagCacheItem=primaryItem
	elseif not primaryItem then
		primaryTagCache={}
	end
	if altTagCacheItem~=altItem then
		altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
		altTagCacheItem=altItem
	elseif not altItem then
		altTagCache={}
	end
	local hand=activeItem.hand()
	local masterybonus={}

	if primaryTagCache["shortsword"] or altTagCache["shortsword"] then
		self.shortswordMastery = 1 + status.stat("shortswordMastery")
		if self.comboStep and self.shortswordMastery > 1 then
			table.insert(masterybonus, {stat = "critChance", amount = 1 + (self.comboStep * self.shortswordMastery)})
		else
			table.insert(masterybonus, {stat = "critChance", amount = 1 * self.shortswordMastery})
		end
	end

	if primaryTagCache["rapier"] or altTagCache["rapier"] then
		self.rapierMastery = 1 + status.stat("rapierMastery")
		if self.comboStep and self.rapierMastery > 1 then
			table.insert(masterybonus,{stat = "dodgetechBonus", amount = (self.rapierMastery-1.0)*0.35})
			table.insert(masterybonus,{stat = "dashtechBonus", amount = (self.rapierMastery-1.0)*0.35})
		end
	end

	if primaryTagCache["katana"] or altTagCache["katana"] then
		self.katanaMastery = 1 + status.stat("katanaMastery")
	end

	if primaryTagCache["scythe"] or altTagCache["scythe"] then
		self.scytheMastery = 1 + status.stat("scytheMastery")
	end

	if primaryTagCache["mace"] or altTagCache["mace"] then
		self.maceMastery = 1 + status.stat("maceMastery")
	end

	if primaryTagCache["shortspear"] or altTagCache["shortspear"] then
		self.shortspearMastery = 1 + status.stat("shortspearMastery")
	end

	if primaryTagCache["axe"] or altTagCache["axe"] then
		self.axeMastery = 1 + status.stat("axeMastery")
	end

	if primaryTagCache["dagger"] or altTagCache["dagger"] then
		self.daggerMastery = 1 + status.stat("daggerMastery")
		table.insert(masterybonus,{stat = "dodgetechBonus", amount = 0.25 * self.daggerMastery})
		if self.comboStep and self.daggerMastery > 1 then
			table.insert(masterybonus,{stat = "powerMultiplier", effectiveMultiplier = self.daggerMastery})
		end
	end

	if primaryTagCache["longsword"] or altTagCache["longsword"] then
		self.longswordMastery = 1 + status.stat("longswordMastery")
		table.insert(masterybonus,{stat = "shieldBash", amount = 1.0 + (self.longswordMastery * 5)})
	end

	if primaryTagCache["broadsword"] or altTagCache["broadsword"] then
		self.broadswordMastery = 1 + status.stat("broadswordMastery")
		if self.comboStep and self.broadswordMastery > 1 then
			table.insert(masterybonus,{stat = "powerMultiplier", effectiveMultiplier = self.broadswordMastery})
		end
	end

	if primaryTagCache["quarterstaff"] or altTagCache["quarterstaff"] then
		self.quarterstaffMastery = 1 + status.stat("quarterstaffMastery")
	end

	if primaryTagCache["hammer"] or altTagCache["hammer"] then
		self.hammerMastery = 1 + status.stat("hammerMastery")
	end

	if primaryTagCache["spear"] or altTagCache["spear"] then
		self.spearMastery = 1 + status.stat("spearMastery")
	end

	status.setPersistentEffects("masterybonus",masterybonus)

	-- ************************************************ END Weapon Masteries ************************************************

	-- ************************************************ Conditional Weapon Bonuses ******************************************
	if primaryTagCache["rapier"] or altTagCache["rapier"] then
		self.rapierTimerBonus=math.min(self.rapierTimerBonus+0.05,5)

		if self.comboStep > 1 then
			status.clearPersistentEffects("multiplierbonus")
			status.clearPersistentEffects("daggerbonus")
		end

		if (not altItem) or (not primaryItem) then
			status.setPersistentEffects("rapierbonus", {
				{stat = "critChance", amount = self.rapierTimerBonus * self.rapierMastery },
				{stat = "dodgetechBonus", amount = 0.35 * self.rapierMastery },
				{stat = "dashtechBonus", amount = 0.35 * self.rapierMastery }
			})
		else
			if (primaryTagCache["rapier"] and altTagCache["dagger"]) or (altTagCache["rapier"] and primaryTagCache["dagger"]) then
				status.setPersistentEffects("rapierbonus", {
					{stat = "dodgetechBonus", amount = 0.25 * self.rapierMastery},
					{stat = "protection", effectiveMultiplier = 1.12 * self.rapierMastery},
					{stat = "dashtechBonus", amount = 0.25 * self.rapierMastery}
				})
			end
		end
	end

	if primaryTagCache["shortspear"] or altTagCache["shortspear"] then
		if (not altItem) or (not primaryItem) then
			status.setPersistentEffects("shortspearbonus", {
				{stat = "critDamage", amount = 0.3 * self.shortspearMastery}
			})
		else
			if primaryTagCache["shield"] or altTagCache["shield"] then
				status.setPersistentEffects("shortspearbonus", {
					{stat = "shieldBash", amount = 10 },
					{stat = "shieldBashPush", amount = 2},
					{stat = "shieldStaminaRegen", effectiveMultiplier = 1.2 * self.shortspearMastery},
					{stat = "defensetechBonus", amount = 0.50}
				})
			end
			if primaryTagCache["shortspear"] and altTagCache["shortspear"] then
				status.setPersistentEffects("shortspearbonus", {
					{stat = "protection", effectiveMultiplier = 0.80 * self.shortspearMastery},
					{stat = "critChance", effectiveMultiplier = 0.5 * self.shortspearMastery}
				})
			end
		end
	end

	if primaryTagCache["dagger"] or altTagCache["dagger"] then
		if self.comboStep and self.comboStep > 1 then
			self.valueModifier = 1 + (1 / (self.comboStep * 2))
			if (primaryTagCache["dagger"] and altTagCache["melee"]) then
				self.valueModifier=math.min(self.valueModifier,1.125)
				status.setPersistentEffects("daggerbonus"..hand, {
					{stat = "protection", effectiveMultiplier = self.valueModifier * self.daggerMastery},
					{stat = "critChance", amount = self.comboStep * self.daggerMastery}
				})
			else
				self.valueModifier=math.min(self.valueModifier,1.25)
				status.setPersistentEffects("daggerbonus", {
					{stat = "protection", effectiveMultiplier = self.valueModifier * self.daggerMastery},
					{stat = "critChance", amount = self.comboStep * self.daggerMastery}
				})
			end
		elseif self.comboStep == 1 or self.comboStep == 0 or not self.comboStep then
			status.setPersistentEffects("daggerbonus"..hand, {
				{stat = "critChance", amount = (self.comboStep or 0) * self.daggerMastery}
			})
		end
		if (primaryTagCache["dagger"] and altTagCache["melee"]) or (altTagCache["dagger"] and primaryTagCache["melee"]) then
			status.addEphemeralEffects({{effect = "runboost5", duration = 0.02 * self.daggerMastery}})
		end
	end

	if primaryTagCache["scythe"] or altTagCache["scythe"] then
		if self.comboStep then
			status.setPersistentEffects("scythebonus", {
				{stat = "critDamage", amount = 0.05+(self.comboStep*0.1)},
				{stat = "critChance", amount = 1+(self.comboStep * self.scytheMastery)}
			})
		else
			status.setPersistentEffects("scythebonus", {
 				{stat = "critDamage", amount = 0.05 * self.scytheMastery},
 				{stat = "critChance", amount = 1 * self.scytheMastery}
 			})
		end
	end

	if primaryTagCache["longsword"] or altTagCache["longsword"] then
		if self.comboStep >=3 then
			status.setPersistentEffects("multiplierbonus", {
				{stat = "critDamage", amount = 0.15 * self.longswordMastery}
			})
		else
			status.setPersistentEffects("multiplierbonus", {})
		end
		if (not altItem) or (not primaryItem) then
			status.setPersistentEffects("longswordbonus", {
				{stat = "attackSpeedUp", amount = 0.7 * self.longswordMastery}
			})
		else
			if primaryTagCache["shield"] or altTagCache["shield"] then
				status.setPersistentEffects("longswordbonus", {
					{stat = "shieldBash", amount = 4 * self.longswordMastery},
					{stat = "shieldBashPush", amount = 1},
					{stat = "defensetechBonus", amount = 0.25 * self.longswordMastery},
					{stat = "healtechBonus", amount = 0.15 * self.longswordMastery}
				})
			end

			if (primaryTagCache["longsword"] and altTagCache["weapon"]) or (altTagCache["longsword"] and primaryTagCache["weapon"]) then
				status.setPersistentEffects("longswordbonus", {
					{stat = "protection", effectiveMultiplier = 0.80 * self.longswordMastery}
				})
				status.addEphemeralEffects({{effect = "runboost5", duration = 0.02 * self.longswordMastery}})
			end
		end
	end

	if primaryTagCache["mace"] or altTagCache["mace"] then
		if (not altItem) or (not primaryItem) then
			status.setPersistentEffects("macebonus", {
				{stat = "stunChance", amount = 2 * self.maceMastery}
			})
		else
			if primaryTagCache["shield"] or altTagCache["shield"] then
				status.setPersistentEffects("macebonus", {
					{stat = "shieldBash", amount = 3 * self.maceMastery},
					{stat = "shieldBashPush", amount = 1},
					{stat = "protection", effectiveMultiplier = 1.10 * self.maceMastery}
				})
			end
			if (primaryTagCache["mace"] and altTagCache["weapon"]) or (altTagCache["mace"] and primaryTagCache["weapon"]) then
				status.setPersistentEffects("macebonus", {
					{stat = "critChance", effectiveMultiplier = 0.85},
					{stat = "stunChance", effectiveMultiplier = 0.50}
				})
				status.addEphemeralEffects({{effect = "runboost5", duration = 0.02 * self.maceMastery}})
			end
		end
	end

	if primaryTagCache["katana"] or altTagCache["katana"] then
		if self.comboStep >=1 then
			mcontroller.controlModifiers({speedModifier = 1 + (self.comboStep / 10)})
		end
		if (not altItem) or (not primaryItem) then
			status.setPersistentEffects("katanabonus", { {stat = "defensetechBonus", amount = 0.15 * self.katanaMastery} })
		else
			if (primaryTagCache["longsword"] or primaryTagCache["katana"] or primaryTagCache["axe"] or primaryTagCache["flail"] or primaryTagCache["shortspear"] or primaryTagCache["mace"]) and
			(altTagCache["longsword"] or altTagCache["katana"] or altTagCache["axe"] or altTagCache["flail"] or altTagCache["shortspear"] or altTagCache["mace"]) then
				status.setPersistentEffects("katanabonus", {
					{stat = "powerMultiplier", effectiveMultiplier = 0.80},
					{stat = "protection", effectiveMultiplier = 0.90}
				})
			end
			if primaryTagCache["shortsword"] or altTagCache["shortsword"]
			or primaryTagCache["dagger"] or altTagCache["dagger"]
			or primaryTagCache["rapier"] or altTagCache["rapier"] then
				status.setPersistentEffects("katanabonus", {
					{stat = "maxEnergy", effectiveMultiplier =	1.15 * self.katanaMastery},
					{stat = "critDamage", amount = 0.2},
					{stat = "dodgetechBonus", amount = 0.25 * self.katanaMastery},
					{stat = "dashtechBonus", amount = 0.25}
				})
			end
		end
	end
		-- ************************************************ END Weapon Abilities ************************************************

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

-- ******************************************
-- FR FUNCTIONS
function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
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
-- FU adds an encapsulating check in Windup, for energy. If there is no energy to consume, the combo weapon cannot attack
function MeleeCombo:windup()
	self.energyMax = math.max(status.resourceMax("energy"),0) -- due to weather and other cases it is possible to have a maximum of under 0.
	if primaryTagCache["melee"] and altTagCache["melee"] then
		self.energyTotal = (self.energyMax * 0.025)
	else
		self.energyTotal = (self.energyMax * 0.01)
	end

	if (status.resource("energy") <= 1) or (not status.consumeResource("energy",self.energyTotal)) then
		--disabling this penalty for now, since instead combo weapons disable combo steps
		--status.setPersistentEffects("meleeEnergyLowPenalty",{{stat = "powerMultiplier", effectiveMultiplier = 0.75}})
		cancelEffects()
		self.comboStep = 1
	else
		status.clearPersistentEffects("meleeEnergyLowPenalty")
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

	self.rapierTimerBonus = 0
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
		self:setState(self.wait)
	else
		self.cooldownTimer = self.cooldowns[self.comboStep]
		-- **** FR cooldown adjustment
		self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep] * ( 1 - attackSpeedUp))
		-- *****
		self.comboStep = 1
	end
end

function MeleeCombo:shouldActivate()
	if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
		if self.comboStep > 1 then
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
	cancelEffects(true)
	if self.helper then
		self.helper:clearPersistent()
	end
	status.clearPersistentEffects("floranFoodPowerBonus")
	status.clearPersistentEffects("slashbonusdmg")
	self.weapon:setDamage()
end

function cancelEffects(fullClear)
	status.clearPersistentEffects("longswordbonus")
	status.clearPersistentEffects("macebonus")
	status.clearPersistentEffects("katanabonus")
	status.clearPersistentEffects("rapierbonus")
	status.clearPersistentEffects("shortspearbonus")
	status.clearPersistentEffects("shortswordbonus")
	status.clearPersistentEffects("daggerbonus")
	status.clearPersistentEffects("daggerbonus"..activeItem.hand())
	status.clearPersistentEffects("scythebonus")
	status.clearPersistentEffects("axebonus")
	status.clearPersistentEffects("hammerbonus")
	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
	status.clearPersistentEffects("listenerBonus")
	status.clearPersistentEffects("listenerbonus")
	status.clearPersistentEffects("masteryBonus")
	status.clearPersistentEffects("masterybonus")
	self.rapierTimerBonus = 0
	self.inflictedHitCounter = 0
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

function fetchTags(iConf)
	if not iConf or not iConf.config then return {} end
	local tags={}
	for k,v in pairs(iConf.config or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	for k,v in pairs(iConf.parameters or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	return tags
end

function tagsToKeys(tags)
	local buffer={}
	for _,v in pairs(tags) do
		buffer[v]=true
	end
	return buffer
end