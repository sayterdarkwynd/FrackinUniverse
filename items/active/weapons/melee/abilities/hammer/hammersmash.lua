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
	self.overCharged = 0 -- overcharged default
	self.hammerMastery = status.stat("hammerMastery") or 0 -- new stat for applying bonuses to hammer functions

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
		self.timerHammer = 0--clear the values each time we swing the hammer
		self.overCharged = 0

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
				self.bombbonus = (status.stat("bombtechBonus") or 1)
				mcontroller.controlModifiers({speedModifier = 0.7 + (self.bombbonus/10)}) --slow down when charging
			
				if self.timerHammer >=100 then --if we havent overcharged but hit 100 bonus, overcharge and reset
					self.overCharged = 1
					self.timerHammer = 0
					status.setPersistentEffects("hammerbonus", {}) 
				end		
				if self.overCharged > 0 then --reset if overCharged
					self.timerHammer = 0
					status.setPersistentEffects("hammerbonus", {})  
				else
					if self.timerHammer < 100 then --otherwise, add bonus
						self.timerHammer = self.timerHammer + 0.5
					    status.setPersistentEffects("hammerbonus", {{stat = "stunChance", amount = self.timerHammer * 1.2 + self.hammerMastery },{stat = "critChance", amount = self.timerHammer + self.hammerMastery }})  			
					end
					if self.timerHammer == 100 then  --at 101, play a sound
						animator.playSound("overCharged")
						animator.burstParticleEmitter("charged")  
					end  					
					if self.timerHammer == 75 then  --at 75, play a sound
						animator.playSound("charged")
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
                    if self.timerHammer > 75 and self.timerHammer < 101 then                  	
				      self.bombbonus = (status.stat("bombtechBonus") or 1)
				      self.hammerMastery = (status.stat("hammerMastery") or 0)
				      local primaryStrike = { power = (self.timerHammer / 4) * self.bombbonus}
				      local secondaryStrike = { power = 0 + self.bombbonus}
				      world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+2,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, primaryStrike)
				      world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-2,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, primaryStrike) 				      
					  world.spawnProjectile("rapierCrit", {mcontroller.position()[1]+1,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, secondaryStrike)
					  world.spawnProjectile("rapierCrit", {mcontroller.position()[1]-1,mcontroller.position()[2]-1}, entity.id(), {0, 0}, false, secondaryStrike) 					      
					  world.spawnProjectile("rapierCrit", {mcontroller.position()[1]+2,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					  world.spawnProjectile("rapierCrit", {mcontroller.position()[1]-2,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike) 				      
					      if self.hammerMastery > 0.5 then
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike) 
					  		world.spawnProjectile("rapierCrit", {mcontroller.position()[1]+3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					  		world.spawnProjectile("rapierCrit", {mcontroller.position()[1]-3,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike) 						      	
					      end
					      if self.hammerMastery > 0.7 then
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					      	world.spawnProjectile("rapierCrit", {mcontroller.position()[1]+4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					  		world.spawnProjectile("rapierCrit", {mcontroller.position()[1]-4,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)  
					      end
					      if self.hammerMastery > 0.9 then		
					  		world.spawnProjectile("rapierCrit", {mcontroller.position()[1]+5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					  		world.spawnProjectile("rapierCrit", {mcontroller.position()[1]-5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike) 					      			      	
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]+5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike)
					      	world.spawnProjectile("regularexplosion", {mcontroller.position()[1]-5,mcontroller.position()[2]-2}, entity.id(), {0, 0}, false, secondaryStrike) 
					      end					      
					  status.setPersistentEffects("hammerbonus", {
							{stat = "protection", effectiveMultiplier = 1.2 + (self.hammerMastery /10) },
							{stat = "grit", effectiveMultiplier = 1.2 + (self.hammerMastery /10)}
					  }) 
					else
						cancelEffects()	
								                         	
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
	status.clearPersistentEffects("listenerBonus")	
	self.rapierTimerBonus = 0	
	self.inflictedHitCounter = 0
	self.timerHammer = 0
end
