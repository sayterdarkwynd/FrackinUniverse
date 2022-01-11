require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/status.lua"
require "/items/active/weapons/melee/meleeslash.lua"
require("/scripts/FRHelper.lua")

-- Axe primary attack
-- Extends default melee attack and overrides windup and fire
AxeCleave = MeleeSlash:new()

function AxeCleave:init()
	self.stances.windup.duration = self.fireTime - self.stances.fire.duration

	attackSpeedUp = 0 -- base attackSpeed bonus

	MeleeSlash.init(self)
	self:setupInterpolation()

	self.inflictedHitCounter = 0
	self.inflictedKills = 0
end

function AxeCleave:windup(windupProgress)
	self.energyTotal = math.max(status.stat("maxEnergy") * 0.07,0) -- due to weather and other cases it is possible to have a maximum of under 0.
	if (status.resource("energy") <= 1) or not (status.consumeResource("energy",math.min((status.resource("energy")-1), self.energyTotal))) then
		self.lowEnergy=true
	else
		self.lowEnergy=false
	end

	--*************************************
	-- FU/FR ADDONS
	setupHelper(self, "axecleave-fire")
	--**************************************

	self.weapon:setStance(self.stances.windup)

	windupProgress = windupProgress or 0
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
	for _, v in ipairs(self.stances.windup.bounceWeaponAngle) do
		v[2] = interp[v[2]]
	end
	for _, v in ipairs(self.stances.windup.weaponAngle) do
		v[2] = interp[v[2]]
	end
	for _, v in ipairs(self.stances.windup.armAngle) do
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
