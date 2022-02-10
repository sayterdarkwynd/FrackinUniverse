require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/FRHelper.lua"


-- to-to : move stats for always-on effects to an array
-- and do the same for raised-only stats/effect
-- investigate bash chance math
-- current system really doesn't do a good job of handling stats that exist only on the item and stats that exist globally on the player

function init()
	self.debug = false
	if self.debug then sb.logInfo("(FR) shield.lua init() for %s", activeItem.hand()) end

	self.aimAngle = 0
	self.aimDirection = 1

	self.active = false
	self.cooldownTimer = config.getParameter("cooldownTime")
	self.activeTimer = 0

	self.animationData = config.getParameter("animationCustom", {})

	self.level = config.getParameter("level", 1)
	self.baseShieldHealth = config.getParameter("baseShieldHealth", 1)
	self.knockback = config.getParameter("knockback", 0)
	self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
	self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)
	self.minActiveTime = config.getParameter("minActiveTime", 0)
	self.cooldownTime = config.getParameter("cooldownTime")
	self.forceWalk = config.getParameter("forceWalk", false)

	animator.setGlobalTag("directives", "")
	animator.setAnimationState("shield", "idle")
	activeItem.setOutsideOfHand(true)

	self.stances = config.getParameter("stances")
	setStance(self.stances.idle)

	self.blockCountShield = 0
	if not self.species or not self.species:succeeded() then
		self.species = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
	end
    if self.species:succeeded() then
        -- yes, we really do need this many
        self.helper = FRHelper:new(self.species:result())
        self.raisedhelper = FRHelper:new(self.species:result())
        self.blockhelper = FRHelper:new(self.species:result())
        self.helper:loadWeaponScripts("shield-update")
        self.raisedhelper:loadWeaponScripts({"shield-raised", "shield-bash"})
        self.blockhelper:loadWeaponScripts("shield-perfectblock")
    end


	-- FU special effects
	-- health effects
	self.critChance = config.getParameter("critChance", 0)
	self.critBonus = config.getParameter("critBonus", 0)
	self.critDamage = config.getParameter("critDamage", 0)
	self.shieldBonusShield = config.getParameter("shieldBonusShield", 0)	-- bonus shield HP
	self.shieldBonusRegen = config.getParameter("shieldBonusRegen", 0)	-- bonus shield regen time
	self.shieldHealthRegen = config.getParameter("shieldHealthRegen", 0)
	shieldEnergyRegen = config.getParameter("shieldEnergyRegen",0)
	shieldHealthBonus = 1.0+config.getParameter("shieldHealthBonus",0)
	shieldEnergyBonus = 1.0+config.getParameter("shieldEnergyBonus",0)
	shieldProtection = config.getParameter("shieldProtection",0)
	shieldStamina = config.getParameter("shieldStamina",0)
	shieldFalling = (1.0+config.getParameter("shieldFalling",0))
	protectionBee = config.getParameter("protectionBee",0)
	protectionAcid = config.getParameter("protectionAcid",0)
	protectionBlackTar = config.getParameter("protectionBlackTar",0)
	protectionBioooze = config.getParameter("protectionBioooze",0)
	protectionPoison = config.getParameter("protectionPoison",0)
	protectionInsanity = config.getParameter("protectionInsanity",0)
	protectionShock = config.getParameter("protectionShock",0)
	protectionSlime = config.getParameter("protectionSlime",0)
	protectionLava = config.getParameter("protectionLava",0)
	protectionFire = config.getParameter("protectionFire",0)
	protectionProto = config.getParameter("protectionProto",0)
	protectionAcid = config.getParameter("protectionAcid",0)
	protectionBlackTar = config.getParameter("protectionBlackTar",0)
	protectionBioooze = config.getParameter("protectionBioooze",0)
	protectionPoison = config.getParameter("protectionPoison",0)
	protectionInsanity = config.getParameter("protectionInsanity",0)
	protectionShock = config.getParameter("protectionShock",0)
	protectionSlime = config.getParameter("protectionSlime",0)
	protectionLava = config.getParameter("protectionLava",0)
	protectionFire = config.getParameter("protectionFire",0)
	protectionProto = config.getParameter("protectionProto",0)
	protectionCold = config.getParameter("protectionCold",0)
	protectionXCold = config.getParameter("protectionXCold",0)
	protectionHeat = config.getParameter("protectionHeat",0)
	protectionXHeat = config.getParameter("protectionXHeat",0)
	protectionRads = config.getParameter("protectionRads",0)
	protectionXRads = config.getParameter("protectionXRads",0)
	stunChance = config.getParameter("stunChance", 0)
	shieldBash = config.getParameter("shieldBash",0)
	shieldBashPush = config.getParameter("shieldBashPush",0)
	--shieldBonusApply()
	-- end FU special effects

	animator.setGlobalTag("directives", "")
	animator.setAnimationState("shield", "idle")
	activeItem.setOutsideOfHand(true)

	self.stances = config.getParameter("stances")
	setStance(self.stances.idle)

	updateAim()
end

function shieldBonusApply(raised)
	local buffer={}
	buffer[#buffer+1]={stat = "maxHealth", effectiveMultiplier = shieldHealthBonus}
	buffer[#buffer+1]={stat = "stunChance", amount =  stunChance}
	buffer[#buffer+1]={stat = "critBonus", amount =  self.critBonus}
	buffer[#buffer+1]={stat = "critDamage", amount =  self.critDamage}
	buffer[#buffer+1]={stat = "maxEnergy", effectiveMultiplier = shieldEnergyBonus}
	buffer[#buffer+1]={stat = "protection", amount = shieldProtection}
	buffer[#buffer+1]={stat = "fallDamageMultiplier", effectiveMultiplier = shieldFalling}
	buffer[#buffer+1]={stat = "shieldStaminaRegen", amount = shieldStamina}
	buffer[#buffer+1]={stat = "shieldBash", amount = shieldBash}
	buffer[#buffer+1]={stat = "shieldBashPush", amount = shieldBashPush}
	if raised then
		buffer[#buffer+1]={stat = "baseShieldHealth", amount = self.shieldBonusShield }
		buffer[#buffer+1]={stat = "energyRegenPercentageRate", amount = shieldEnergyRegen}
		buffer[#buffer+1]={stat = "beestingImmunity", amount = protectionBee}
		buffer[#buffer+1]={stat = "sulphuricImmunity", amount = protectionAcid}
		buffer[#buffer+1]={stat = "blacktarImmunity", amount = protectionBlackTar}
		buffer[#buffer+1]={stat = "biooozeImmunity", amount = protectionBioooze}
		buffer[#buffer+1]={stat = "poisonStatusImmunity", amount = protectionPoison}
		buffer[#buffer+1]={stat = "insanityImmunity", amount = protectionInsanity}
		buffer[#buffer+1]={stat = "shockStatusImmunity", amount = protectionShock}
		buffer[#buffer+1]={stat = "slimeImmunity", amount = protectionSlime}
		buffer[#buffer+1]={stat = "lavaImmunity", amount = protectionLava}
		buffer[#buffer+1]={stat = "fireStatusImmunity", amount = protectionFire}
		buffer[#buffer+1]={stat = "protoImmunity", amount = protectionProto}
		buffer[#buffer+1]={stat = "sulphuricImmunity", amount = protectionAcid}
		buffer[#buffer+1]={stat = "blacktarImmunity", amount = protectionBlackTar}
		buffer[#buffer+1]={stat = "biooozeImmunity", amount = protectionBioooze}
		buffer[#buffer+1]={stat = "poisonStatusImmunity", amount = protectionPoison}
		buffer[#buffer+1]={stat = "insanityImmunity", amount = protectionInsanity}
		buffer[#buffer+1]={stat = "electricStatusImmunity", amount = protectionShock}
		buffer[#buffer+1]={stat = "slimeImmunity", amount = protectionSlime}
		buffer[#buffer+1]={stat = "lavaImmunity", amount = protectionLava}
		buffer[#buffer+1]={stat = "biomecoldImmunity", amount = protectionCold}
		buffer[#buffer+1]={stat = "ffextremecoldImmunity", amount = protectionXCold}
		buffer[#buffer+1]={stat = "biomeheatImmunity", amount = protectionHeat}
		buffer[#buffer+1]={stat = "ffextremeheatImmunity", amount = protectionXHeat}
		buffer[#buffer+1]={stat = "biomeradiationImmunity", amount = protectionRads}
		buffer[#buffer+1]={stat = "ffextremeradiationImmunity", amount = protectionXRads}
	end
	status.setPersistentEffects("shieldEffects",buffer)
end

function isShield(name) -- detect if they have a shield equipped for racial tag checks
	if root.itemHasTag(name, "shield") then
		return true
	end
	return false
end

function update(dt, fireMode, shiftHeld)

    shieldBonusApply(self.active)

    if not self.species:succeeded() then init() end
    if self.helper then self.helper:runScripts("shield-update", self, dt, fireMode, shiftHeld) end

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.blockCountShield == nil then
        self.blockCountShield = 0
	end

	if not self.active and fireMode == "primary" and self.cooldownTimer == 0 and status.resourcePositive("shieldStamina") then
        raiseShield()
	end

	if self.active then
        self.activeTimer = self.activeTimer + dt

        self.damageListener:update()

        -- ************************************** FU SPECIALS **************************************
        status.modifyResourcePercentage("health", self.shieldHealthRegen * dt)
        -- *****************************************************************************************

        if status.resourcePositive("perfectBlock") then
            animator.setGlobalTag("directives", self.perfectBlockDirectives)
        else
            animator.setGlobalTag("directives", "")
        end

        if self.forceWalk then
            mcontroller.controlModifiers({runningSuppressed = true})
        end

        if (fireMode ~= "primary" and self.activeTimer >= self.minActiveTime) or not status.resourcePositive("shieldStamina") then
            lowerShield()
        end
	end

	updateAim()
end

function uninit()
    if self.helper then
        self.helper:clearPersistent()
        self.raisedhelper:clearPersistent()
        self.blockhelper:clearPersistent()
    end
	status.clearPersistentEffects("shieldBonus")
	status.clearPersistentEffects("shieldEffects")
	status.clearPersistentEffects(activeItem.hand().."Shield")
	activeItem.setItemShieldPolys({})
	activeItem.setItemDamageSources({})

end

function updateAim()
	local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())

	if self.stance.allowRotate then
        self.aimAngle = aimAngle
	end
	activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

	if self.stance.allowFlip then
        self.aimDirection = aimDirection
	end
	activeItem.setFacingDirection(self.aimDirection)

	animator.setGlobalTag("hand", isNearHand() and "near" or "far")
	activeItem.setOutsideOfHand(not self.active or isNearHand())
end

function isNearHand()
	return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end

function setStance(stance)
	self.stance = stance
	self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
	self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function raiseShield()
	setStance(self.stances.raised)
	animator.setAnimationState("shield", "raised")
	animator.playSound("raiseShield")
	self.active = true
	self.activeTimer = 0
	status.setPersistentEffects(activeItem.hand().."Shield", {{stat = "shieldHealth", amount = shieldHealth()}})
	local shieldPoly = animator.partPoly("shield", "shieldPoly")
	activeItem.setItemShieldPolys({shieldPoly})

    shieldBonusApply(self.active)

	if self.knockback > 0 then
        local knockbackDamageSource = {
            poly = shieldPoly,
            damage = 0,
            damageType = "Knockback",
            sourceEntity = activeItem.ownerEntityId(),
            team = activeItem.ownerTeam(),
            knockback = self.knockback,
            rayCheck = true,
            damageRepeatTimeout = 0.25
        }
        activeItem.setItemDamageSources({ knockbackDamageSource })
	end

    -- ******************* BEGIN FR RACIALS FOR WHEN SHIELD IS RAISED
    if self.raisedhelper then self.raisedhelper:runScripts("shield-raised", self) end
    -- ******************** END RAISED SHIELD SPECIALS

	self.damageListener = damageListener("damageTaken", function(notifications)
	for _,notification in pairs(notifications) do
            if notification.hitType == "ShieldHit" then
                -- *** set up shield bash values *** --
                self.randomBash = math.random(100) + config.getParameter("shieldBash",0) + status.stat("shieldBash")
                if not status.resource("energy") then
                    self.energyval= 0
                else
                    self.energyval= (status.resource("energy") / status.stat("maxEnergy")) * 100
                end
                -- end shieldbash Init
                if status.resourcePositive("perfectBlock") then

                    if (self.energyval) >= 50 and (self.randomBash) >= 50 then -- greater chance to Shield Bash when perfect blocking
                        bashEnemy()
                    end

					--No catch case for this sound since it's required by vanilla.
					animator.playSound("perfectBlock")

					if self.animationData.particleEmitters and self.animationData.particleEmitters.perfectBlock then
						animator.burstParticleEmitter("perfectBlock")
					end

                    -- *******************************************************
                    self.blockCountShield = self.blockCountShield + 1

                    -- *******************************************************
                    -- Begin racial Perfect Blocking scripts
                    -- *******************************************************
                    if self.blockhelper then self.blockhelper:runScripts("shield-perfectblock", self) end

                    refreshPerfectBlock()
                elseif status.resourcePositive("shieldStamina") then
                    if (self.energyval) >= 50 and (self.randomBash) >= 100 then -- Shield Bash when perfect blocking
                        bashEnemy()
                    end
                    if self.debug then sb.logInfo("(FR) shield.lua: hitType %s received, blockCountShield = %s, blockCountShield reset",notification.hitType, self.blockCountShield) end
                    clearEffects()
                    animator.playSound("block")
                else
                    animator.playSound("break")
                    if (self.energyval) <= 20 and (self.randomBash) >= 50 or (self.randomBash) >= 100 then -- if tired, we could end up stunned when our shield breaks!
                        status.addEphemeralEffect("stun",0.75)
                    end
                    if self.debug then sb.logInfo("(FR) shield.lua: hitType %s received, blockCountShield = %s, blockCountShield reset",notification.hitType, self.blockCountShield) end
                    clearEffects()
                end
                animator.setAnimationState("shield", "block")
                return
            else
                if self.debug then sb.logInfo("(FR) shield.lua: non-ShieldHit: %s", notification.hitType) end
                -- hit is required to do damage, else collisions with, e.g., rain could trigger the reset
                if notification.healthLost --[[.damageDealt?]] > 0 then
                    if self.debug then sb.logInfo("(FR) shield.lua: hitType %s received, blockCountShield = %s, blockCountShield reset",notification.hitType, self.blockCountShield) end
                    clearEffects()
                end
            end
        end
	end)

	refreshPerfectBlock()
end

function bashEnemy()
    self.energyValue = status.resource("energy") or 0

	-- apply bonus stun
	self.stunBonus = config.getParameter("shieldBash",0) + config.getParameter("shieldBashPush",0)
	self.stunValue = math.random(100) + self.stunBonus

    if self.raisedhelper then self.raisedhelper:runScripts("shield-bash", self) end

	-- lets limit how much damage they can do
	self.damageLimit = (self.energyval/50) + (status.stat("health")/50) + math.random(6) + (status.stat("shieldBashBonus"))

	if status.resourcePositive("perfectBlock") then
        self.pushBack = math.random(24) + config.getParameter("shieldBashPush",0) + status.stat("shieldBashPush") + 6
		if self.stunValue >=100 then
            local params2 = { speed=20, power = 0 , damageKind = "default", knockback = 0 } -- Stun
            world.spawnProjectile("shieldBashStunProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params2)
		end
	else
		self.pushBack = math.random(20) + config.getParameter("shieldBashPush",0) + status.stat("shieldBashPush") + 2
	end
    local params = { speed=20, power = self.damageLimit , damageKind = "default", knockback = self.pushBack } -- Shield Bash
    world.spawnProjectile("fu_genericBlankProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params)
    status.modifyResource("energy", self.energyValue * -0.2 )	-- consume energy

	if animator.hasSound("shieldBash") then
		--Protection for if the user hasn't specified shield bash sounds
		animator.playSound("shieldBash")
	end

	--Alright Bob I'll take "Slapping chucklefish for not offering animator.hasParticle" for $500.
	if self.animationData.particleEmitters and self.animationData.particleEmitters.shieldBashHit then
		--Protection for if the user hasn't specified shield bash partiles
		animator.burstParticleEmitter("shieldBashHit")
	end
end

function clearEffects()
    if self.blockhelper then self.blockhelper:clearPersistent() end
	self.blockCountShield = 0
end

function refreshPerfectBlock()
	local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
	status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
	status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end

function lowerShield()
    if self.raisedhelper then self.raisedhelper:clearPersistent() end
	setStance(self.stances.idle)
	animator.setGlobalTag("directives", "")
	animator.setAnimationState("shield", "idle")
	animator.playSound("lowerShield")
	self.active = false
	self.activeTimer = 0
	status.clearPersistentEffects(activeItem.hand().."Shield")
	activeItem.setItemShieldPolys({})
	activeItem.setItemDamageSources({})
	self.cooldownTimer = self.cooldownTime
	status.clearPersistentEffects("shieldBonus")
	status.clearPersistentEffects("shieldEffects")
end

function shieldHealth()
	return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end
