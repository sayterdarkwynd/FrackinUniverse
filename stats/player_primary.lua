require "/scripts/status.lua"
require "/scripts/achievements.lua"

function init()
	self.lastYPosition = 0
	self.lastYVelocity = 0
	self.fallDistance = 0
	self.hitInvulnerabilityTime = 0
	self.shieldHitInvulnerabilityTime = 0
	self.suffocateSoundTimer = 0
	self.ouchCooldown = 0

	local ouchNoise = status.statusProperty("ouchNoise")
	if ouchNoise then
		animator.setSoundPool("ouch", {ouchNoise})
	end

	self.inflictedDamage = damageListener("inflictedDamage", inflictedDamageCallback)

	message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId) status.addEphemeralEffect(effectConfig, duration, sourceEntityId) end)
end

function inflictedDamageCallback(notifications)
	for _,notification in ipairs(notifications) do
		if notification.hitType == "Kill" then
			if world.entityExists(notification.targetEntityId) then
				local entityType = world.entityType(notification.targetEntityId)
				local eventFields = entityEventFields(notification.targetEntityId)
				util.mergeTable(eventFields, worldEventFields())
				eventFields.damageSourceKind = notification.damageSourceKind

				if entityType == "object" then
					recordEvent(entity.id(), "killObject", eventFields)

				elseif entityType == "npc" or entityType == "monster" or entityType == "player" then
					recordEvent(entity.id(), "kill", eventFields)
				end

				if entityType == "monster" then
					local monsterClass = root.monsterParameters(eventFields.monsterType).monsterClass or "standard"
					recordEvent(entity.id(), "killMonster", {monsterClass = monsterClass})
				end
			else
				-- TODO: better method for getting data on killed entities
				sb.logInfo("Skipped event recording for nonexistent entity %s", notification.targetEntityId)
			end
		end
	end
end

function applyDamageRequest(damageRequest)
	if world.getProperty("invinciblePlayers") then return {} end

	local hitInvulnerability = self.hitInvulnerabilityTime > 0 and damageRequest.damageSourceKind ~= "applystatus"
	if damageRequest.damageSourceKind ~= "falling" and (hitInvulnerability or world.getProperty("nonCombat")) then
		return {}
	end

	status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)
	if damageRequest.damageSourceKind == "applystatus" then
		return {}
	end

	local damage = 0
	if damageRequest.damageType == "Damage" or damageRequest.damageType == "Knockback" then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, status.stat("protection"))
	elseif damageRequest.damageType == "IgnoresDef" or damageRequest.damageType == "Environment" then
		damage = damage + damageRequest.damage
	elseif damageRequest.damageType == "Status" then
		-- only apply status effects
		status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)
		return {}
	end

	if status.resourcePositive("damageAbsorption") then
		local damageAbsorb = math.min(damage, status.resource("damageAbsorption"))
		status.modifyResource("damageAbsorption", -damageAbsorb)
		damage = damage - damageAbsorb
	end

	if damageRequest.hitType == "ShieldHit" then
		if self.shieldHitInvulnerabilityTime == 0 then
			local preShieldDamageHealthPercentage = damage / status.resourceMax("health")
			self.shieldHitInvulnerabilityTime = status.statusProperty("shieldHitInvulnerabilityTime") * math.min(preShieldDamageHealthPercentage, 1.0)

			if not status.resourcePositive("perfectBlock") then
				status.modifyResource("shieldStamina", -damage / status.stat("shieldHealth"))
			end
		end

		status.setResourcePercentage("shieldStaminaRegenBlock", 1.0)
		damage = 0
		damageRequest.statusEffects = {}
		damageRequest.damageSourceKind = "shield"
	end

	local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
	local resistance = status.stat(elementalStat)
	damage = damage - (resistance * damage)

	local healthLost = math.min(damage, status.resource("health"))
	if healthLost > 0 and damageRequest.damageType ~= "Knockback" then
		status.modifyResource("health", -healthLost)
		if self.ouchCooldown <= 0 then
			animator.playSound("ouch")
			self.ouchCooldown = 0.5
		end

		local damageHealthPercentage = damage / status.resourceMax("health")
		if damageHealthPercentage > status.statusProperty("hitInvulnerabilityThreshold") then
			self.hitInvulnerabilityTime = status.statusProperty("hitInvulnerabilityTime")
		end
	end

	local knockbackFactor = (1 - math.min(1.0,status.stat("grit")))

	local knockbackMomentum = vec2.mul(damageRequest.knockbackMomentum, knockbackFactor)
	local knockback = vec2.mag(knockbackMomentum)
	if knockback > status.stat("knockbackThreshold") then
		mcontroller.setVelocity({0,0})
		local dir = knockbackMomentum[1] > 0 and 1 or -1
		mcontroller.addMomentum({dir * knockback / 1.41, knockback / 1.41})
	end

	local hitType = damageRequest.hitType
	if not status.resourcePositive("health") then
		hitType = "kill"
	end
	return {{
		sourceEntityId = damageRequest.sourceEntityId,
		targetEntityId = entity.id(),
		position = mcontroller.position(),
		damageDealt = damage,
		healthLost = healthLost,
		hitType = hitType,
		damageSourceKind = damageRequest.damageSourceKind,
		targetMaterialKind = status.statusProperty("targetMaterialKind")
	}}
end

function notifyResourceConsumed(resourceName, amount)
	if resourceName == "energy" and amount > 0 then
		status.setResourcePercentage("energyRegenBlock", 1.0)
	end
end

function update(dt)
	local minimumFallDistance = 14
	local fallDistanceDamageFactor = 3
	local minimumFallVel = 40
	local baseGravity = 80
	local gravityDiffFactor = 1 / 30.0

	local curYPosition = mcontroller.yPosition()
	local yPosChange = curYPosition - (self.lastYPosition or curYPosition)

	self.ouchCooldown = math.max(0.0, self.ouchCooldown - dt)

	if self.fallDistance > minimumFallDistance and -self.lastYVelocity > minimumFallVel and mcontroller.onGround() then
		local damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor
		damage = damage * (1.0 + (world.gravity(mcontroller.position()) - baseGravity) * gravityDiffFactor)
		damage = damage * status.stat("fallDamageMultiplier")
		status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = damage,
				damageSourceKind = "falling",
				sourceEntityId = entity.id()
			})
	end

	if mcontroller.yVelocity() < -minimumFallVel and not mcontroller.onGround() then
		self.fallDistance = self.fallDistance + -yPosChange
	else
		self.fallDistance = 0
	end

	self.lastYPosition = curYPosition
	self.lastYVelocity = mcontroller.yVelocity()

	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	if status.statPositive("breathProtection") or world.breathable(mouthPosition) then
		status.modifyResource("breath", status.stat("breathRegenerationRate") * dt)
	else
		status.modifyResource("breath", -status.stat("breathDepletionRate") * dt)
	end

	if not status.resourcePositive("breath") then
		self.suffocateSoundTimer = self.suffocateSoundTimer - dt
		if self.suffocateSoundTimer <= 0 then
			self.suffocateSoundTimer = 0.5 + (0.5 * status.resourcePercentage("health"))
			animator.playSound("suffocate")
		end
		status.modifyResourcePercentage("health", -status.statusProperty("breathHealthPenaltyPercentageRate") * dt)
	else
		self.suffocateSoundTimer = 0
	end

	self.hitInvulnerabilityTime = math.max(self.hitInvulnerabilityTime - dt, 0)
	local flashTime = status.statusProperty("hitInvulnerabilityFlash")

	if self.hitInvulnerabilityTime > 0 then
		if math.fmod(self.hitInvulnerabilityTime, flashTime) > flashTime / 2 then
			status.setPrimaryDirectives(status.statusProperty("damageFlashOffDirectives"))
		else
			status.setPrimaryDirectives(status.statusProperty("damageFlashOnDirectives"))
		end
	else
		status.setPrimaryDirectives()
	end

	if status.resourceLocked("energy") and status.resourcePercentage("energy") == 1 then
		animator.playSound("energyRegenDone")
	end

	if status.resource("energy") == 0 then
		if not status.resourceLocked("energy") then
			animator.playSound("outOfEnergy")
			animator.burstParticleEmitter("outOfEnergy")
		end

		status.setResourceLocked("energy", true)
	elseif status.resourcePercentage("energy") == 1 then
		status.setResourceLocked("energy", false)
	end

	if not status.resourcePositive("energyRegenBlock") then
		status.modifyResourcePercentage("energy", status.stat("energyRegenPercentageRate") * dt)
	end

	self.shieldHitInvulnerabilityTime = math.max(self.shieldHitInvulnerabilityTime - dt, 0)
	if not status.resourcePositive("shieldStaminaRegenBlock") then
		status.modifyResourcePercentage("shieldStamina", status.stat("shieldStaminaRegen") * dt)
		status.modifyResourcePercentage("perfectBlockLimit", status.stat("perfectBlockLimitRegen") * dt)
	end

	self.inflictedDamage:update()

	if mcontroller.atWorldLimit(true) then
		status.setResourcePercentage("health", 0)
	end
end

function overheadBars()
	local bars = {}

	if status.statPositive("shieldHealth") then
		table.insert(bars, {
			percentage = status.resource("shieldStamina"),
			color = status.resourcePositive("perfectBlock") and {255, 255, 200, 255} or {200, 200, 0, 255}
		})
	end

	return bars
end
