require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/melee/meleeslash.lua"
require("/scripts/FRHelper.lua")

-- Hammer primary attack
-- Extends default melee attack and overrides windup and fire
HammerSmash = MeleeSlash:new()
function HammerSmash:init()
	self.stances.windup.duration = self.fireTime - self.stances.preslash.duration - self.stances.fire.duration

	self.timerHammer = 0 --for hammer crit/stun bonus (FU)
    self.flashTimer = 0

	MeleeSlash.init(self)
	self:setupInterpolation()
end

function HammerSmash:windup(windupProgress)
	self.energyTotal = (status.stat("maxEnergy") * 0.10)
		if status.resource("energy") <= 1 then 
			status.modifyResource("energy",1) 
			cancelEffects()
		end 
		if status.resource("energy") == 1 then 
			cancelEffects() 
		end
	if status.consumeResource("energy",math.min((status.resource("energy")-1), self.energyTotal)) then 

		self.weapon:setStance(self.stances.windup)
		--*************************************
		-- FU/FR ADDONS
		setupHelper(self, "hammersmash-fire")
		--**************************************
		self.timerHammer = 0
		local windupProgress = windupProgress or 0
		local bounceProgress = 0
		while self.fireMode == "primary" and (self.allowHold ~= false or windupProgress < 1) do
	        if windupProgress < 1 then
	            windupProgress = math.min(1, windupProgress + (self.dt / self.stances.windup.duration))
	            self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
	        else
	            bounceProgress = math.min(1, bounceProgress + (self.dt / self.stances.windup.bounceTime))
	            self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:bounceWeaponAngle(bounceProgress)

		--**************************************
			-- increase "charge" the longer it is held. cannot pass 100.
			if self.timerHammer <= 100 then
				self.timerHammer = self.timerHammer + 0.5
			    status.setPersistentEffects("hammerbonus", {
					{stat = "stunChance", amount = self.timerHammer * 1.2 },
					{stat = "critChance", amount = self.timerHammer }
				})  			
			end
			if self.timerHammer == 75 then
				animator.playSound("charged")
				animator.burstParticleEmitter("charged")  
				status.addEphemeralEffects{{effect = "hammerbonus", duration = 0.4}}
			end
			if self.timerHammer > 101 then
				self.timerHammer = 0
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
end

function HammerSmash:winddown(windupProgress)
	self.weapon:setStance(self.stances.windup)
	while windupProgress > 0 do
        if self.fireMode == "primary" then
            self:setState(self.windup, windupProgress)
            return true
        end

        windupProgress = math.max(0, windupProgress - (self.dt / self.stances.windup.duration))
        self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
        coroutine.yield()
        cancelEffects()
	end
end

function HammerSmash:fire()
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

	animator.setAnimationState("swoosh", "fire")
	animator.playSound("fire")
	animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

	local smashMomentum = self.smashMomentum
	smashMomentum[1] = smashMomentum[1] * mcontroller.facingDirection()
	mcontroller.addMomentum(smashMomentum)


	-- ******************* FR ADDONS FOR HAMMER SWINGS
    if self.helper then
		self.helper:runScripts("hammersmash-fire", self)
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
                    animator.playSound("groundImpact")
                    if self.timerHammer > 75 then                  	
				      self.bombbonus = (status.stat("bombtechBonus") or 1)
				      local configBombDrop = { power = (self.timerHammer / 4) * self.bombbonus}
				      world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+4,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, configBombDrop)
				      world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-4,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, configBombDrop) 
					    status.setPersistentEffects("hammerbonus", {
							{stat = "protection", effectiveMultiplier = 1.2 },
							{stat = "grit", effectiveMultiplier = 1.2 }
						}) 
					else
						self.timerHammer = 0				                         	
                    end
                end
            end
        end
        coroutine.yield()
    end

	self.cooldownTimer = self:cooldownTime()
end

function HammerSmash:setupInterpolation()
	for i, v in ipairs(self.stances.windup.bounceWeaponAngle) do
        v[2] = interp[v[2]]
	end
	for i, v in ipairs(self.stances.windup.bounceArmAngle) do
        v[2] = interp[v[2]]
	end
	for i, v in ipairs(self.stances.windup.weaponAngle) do
        v[2] = interp[v[2]]
	end
	for i, v in ipairs(self.stances.windup.armAngle) do
        v[2] = interp[v[2]]
	end
end

function HammerSmash:bounceWeaponAngle(ratio)
	local weaponAngle = interp.ranges(ratio, self.stances.windup.bounceWeaponAngle)
	local armAngle = interp.ranges(ratio, self.stances.windup.bounceArmAngle)

	return util.toRadians(weaponAngle), util.toRadians(armAngle)
end

function HammerSmash:windupAngle(ratio)
	local weaponRotation = interp.ranges(ratio, self.stances.windup.weaponAngle)
	local armRotation = interp.ranges(ratio, self.stances.windup.armAngle)

	return util.toRadians(weaponRotation), util.toRadians(armRotation)
end


function HammerSmash:uninit()
	cancelEffects()
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
	self.rapierTimerBonus = 0	
	self.timerHammer = 0
end
