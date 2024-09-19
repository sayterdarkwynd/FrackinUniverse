require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/melee/meleeslash.lua"
require("/scripts/FRHelper.lua")

-- greataxe primary attack
-- Extends default melee attack and overrides windup and fire
GreataxeSmash = MeleeSlash:new()
function GreataxeSmash:init()
	self.stances.windup.duration = self.fireTime - self.stances.preslash.duration - self.stances.fire.duration

	self.timerGreataxe = 0 --for greataxe crit/stun bonus (FU)
	self.overCharged = 0 -- overcharged default

	MeleeSlash.init(self)
	self:setupInterpolation()
end

function GreataxeSmash:windup(windupProgress)
	self.energyTotal = math.max(status.stat("maxEnergy") * 0.10,0) -- due to weather and other cases it is possible to have a maximum of under 0.
	if (status.resource("energy") <= 1) or not (status.consumeResource("energy",math.min((status.resource("energy")-1), self.energyTotal))) then
		self.timerGreataxe = 0
		self.lowEnergy=true
	else
		self.lowEnergy=false
	end

	self.weapon:setStance(self.stances.windup)
	--*************************************
	-- FU/FR ADDONS
	setupHelper(self, "GreataxeSmash-fire")
	--**************************************
	self.timerGreataxe = 0--clear the values each time we swing the greataxe
	self.overCharged = 0

	windupProgress = windupProgress or 0
	local bounceProgress = 0
	if self.fireMode == "primary" and (self.allowHold ~= false or windupProgress < 1) then
		status.setStatusProperty(activeItem.hand().."Firing",true)
	end
	while self.fireMode == "primary" and (self.allowHold ~= false or windupProgress < 1) do
		if windupProgress < 1 then
			windupProgress = math.min(1, windupProgress + (self.dt / self.stances.windup.duration))
			self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
		else
			bounceProgress = math.min(1, bounceProgress + (self.dt / self.stances.windup.bounceTime))
			self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:bounceWeaponAngle(bounceProgress)

			--**************************************

			-- increase "charge" the longer it is held. cannot pass 100.
			local bombBonus = status.stat("bombtechBonus")
			mcontroller.controlModifiers({speedModifier = 0.7 + (bombBonus/10)}) --slow down when charging

			if self.lowEnergy or (self.timerGreataxe >=100) then --if we havent overcharged but hit 100 bonus, overcharge and reset
				self.overCharged = 1
				self.timerGreataxe = 0
				status.setPersistentEffects("greataxeMasteryBonus", {})
			end
			if self.overCharged > 0 then --reset if overCharged
				self.timerGreataxe = 0
				status.setPersistentEffects("greataxeMasteryBonus", {})
			else
				if self.timerGreataxe < 100 then --otherwise, add bonus. crit chance scales from 0 to 100%, reaching it quicker with higher mastery. crit damage reaches 1% at max, multiplied by mastery value (30% makes it 1.3% CD)
					self.timerGreataxe = self.timerGreataxe + 0.5
					local greataxeMastery=1+status.stat("axeMastery")
					status.setPersistentEffects("greataxeMasteryBonus", {{stat = "critChance", amount = self.timerGreataxe * 1.05 * greataxeMastery },{stat = "critDamage", amount = greataxeMastery*self.timerGreataxe/100}})
					world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","greataxeMasteryBonus")
				end
				if self.timerGreataxe == 100 then	--at 101, play a sound
					if animator.hasSound("overCharged") then
						animator.playSound("overCharged")
					elseif animator.hasSound("groundImpact") then
						animator.playSound("groundImpact")
					elseif animator.hasSound("fire") then
						animator.playSound("fire")
					end
					--animator.burstParticleEmitter("charged")
				end
				if self.timerGreataxe == 75 then	--at 75, play a sound
					if animator.hasSound("charged") then
						animator.playSound("charged")
					elseif animator.hasSound("groundImpact") then
						animator.playSound("groundImpact")
					elseif animator.hasSound("fire") then
						animator.playSound("fire")
					end
					status.addEphemeralEffects{{effect = "hammerbonus", duration = 0.4}}
				end
			end
	--**************************************
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

function GreataxeSmash:winddown(windupProgress)
	self.weapon:setStance(self.stances.windup)
	while windupProgress > 0 do
		if self.fireMode == "primary" then
			self:setState(self.windup, windupProgress)
			return true
		end

		windupProgress = math.max(0, windupProgress - (self.dt / self.stances.windup.duration))
		self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
		coroutine.yield()
		self.timerGreataxe = 0
	end
	status.setStatusProperty(activeItem.hand().."Firing",false)
end

function GreataxeSmash:fire()
	status.setStatusProperty(activeItem.hand().."Firing",true)
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	animator.setAnimationState("swoosh", "fire")
	if animator.hasSound("fire") then
		animator.playSound("fire")
	end
	animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

	local smashMomentum = self.smashMomentum
	smashMomentum[1] = smashMomentum[1] * mcontroller.facingDirection()
	mcontroller.addMomentum(smashMomentum)


	-- ******************* FR ADDONS FOR GREATAXE SWINGS
	if self.helper then
		self.helper:runScripts("GreataxeSmash-fire", self)
	end
	-- ***********************************************
	local smashTimer = self.stances.fire.smashTimer
	local duration = self.stances.fire.duration
	while smashTimer > 0 or duration > 0 do
		smashTimer = math.max(0, smashTimer - self.dt)
		duration = math.max(0, duration - self.dt)

		local damageArea = partDamageArea("swoosh")
		if not damageArea and smashTimer > 0 then
				damageArea = partDamageArea("blade")
		end
		self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)

		if smashTimer > 0 then
			local groundImpact = world.polyCollision(poly.translate(poly.handPosition(animator.partPoly("blade", "groundImpactPoly")), mcontroller.position()))
			if mcontroller.onGround() or groundImpact then
				smashTimer = 0
				if groundImpact then
					animator.burstParticleEmitter("groundImpact")
					if animator.hasSound("groundImpact") then
						animator.playSound("groundImpact")
					end
					if self.timerGreataxe > 75 and self.timerGreataxe < 101 then
						local bombBonus = status.stat("bombtechBonus")
						local greataxeMastery = status.stat("axeMastery")
						local primaryStrike = { power = (self.timerGreataxe / 4) * bombBonus}
						local secondaryStrike = { power = 0 + bombBonus}
						world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+2,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, primaryStrike)
						world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-2,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, primaryStrike)
						world.spawnProjectile("spearCrit", {mcontroller.position()[1]+1,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, secondaryStrike)
						world.spawnProjectile("spearCrit", {mcontroller.position()[1]-1,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, secondaryStrike)
						world.spawnProjectile("spearCrit", {mcontroller.position()[1]+2,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
						world.spawnProjectile("spearCrit", {mcontroller.position()[1]-2,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
						if greataxeMastery > 0.5 then
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]+3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]-3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
						end
						if greataxeMastery > 0.7 then
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]+4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]-4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
						end
						if greataxeMastery > 0.9 then
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]+5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("spearCrit", {mcontroller.position()[1]-5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
							world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
						end
						--(20+(1/10 mastery modifier))% knockback resistance, and same amount as protection multiplier
						status.setPersistentEffects("greataxeMasteryBonus", {
							{stat = "protection", effectiveMultiplier = 1.2 + (greataxeMastery /10) },
							{stat = "grit", amount = 0.2 + (greataxeMastery /10)}
						})
						world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","greataxeMasteryBonus")
					else
						status.setPersistentEffects("greataxeMasteryBonus", {})
						self.timerGreataxe = 0
					end
				end
			end
		end
		coroutine.yield()
		end

	self.cooldownTimer = self:cooldownTime()
end

function GreataxeSmash:setupInterpolation()
	for _, v in ipairs(self.stances.windup.bounceWeaponAngle) do
		v[2] = interp[v[2]]
	end
	for _, v in ipairs(self.stances.windup.bounceArmAngle) do
		v[2] = interp[v[2]]
	end
	for _, v in ipairs(self.stances.windup.weaponAngle) do
		v[2] = interp[v[2]]
	end
	for _, v in ipairs(self.stances.windup.armAngle) do
		v[2] = interp[v[2]]
	end
end

function GreataxeSmash:bounceWeaponAngle(ratio)
	local weaponAngle = interp.ranges(ratio, self.stances.windup.bounceWeaponAngle)
	local armAngle = interp.ranges(ratio, self.stances.windup.bounceArmAngle)

	return util.toRadians(weaponAngle), util.toRadians(armAngle)
end

function GreataxeSmash:windupAngle(ratio)
	local weaponRotation = interp.ranges(ratio, self.stances.windup.weaponAngle)
	local armRotation = interp.ranges(ratio, self.stances.windup.armAngle)

	return util.toRadians(weaponRotation), util.toRadians(armRotation)
end

function GreataxeSmash:uninit()
	self.timerGreataxe = 0
	if self.helper then
		self.helper:clearPersistent()
	end
	self.blockCount = 0
	status.setStatusProperty(activeItem.hand().."Firing",nil)
end
