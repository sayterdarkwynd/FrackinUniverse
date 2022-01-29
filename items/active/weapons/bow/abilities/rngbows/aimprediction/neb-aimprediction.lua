--Modified bow shot ability that drains energy while drawing and holding, with configurable drain rates. Has an animation state for when arrows have been loosed
require "/scripts/vec2.lua"
require "/scripts/util.lua"

-- Bow primary ability
NebRNGAimBot = WeaponAbility:new()

function NebRNGAimBot:init()
	--General Init
	self.energyPerShot = self.energyPerShot or 0
	animator.setGlobalTag("directives", config.getParameter("directives", ""))
	self.paletteSwaps = config.getParameter("paletteSwaps")
	self.elementalType = config.getParameter("elementalType")
	self.arrowVariant = config.getParameter("animationParts")

	--Setup the bow functions
	self.drawTimer = 0
	animator.setAnimationState("bow", "idle")
	self.cooldownTimer = 0
	self.aimOutOfReach = false
	self.aimTypeSwitchTimer = 0

	--Setup the marking
	self.maxTargets = 1
	self.projectileSpeed = 0
	self.targets = {}
	self.predictedPosition = nil

	--Reset Local Animator
	activeItem.setScriptedAnimationParameter("entities", {})
	activeItem.setScriptedAnimationParameter("entityMarker", self.entityMarker)

	--Ensure a proper setup of the weapon
	self:reset()

	--Register the gravity of the projectile
	self.projectileGravityMultiplier = root.projectileGravityMultiplier(self.powerProjectileType or self.altProjectileType)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function NebRNGAimBot:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	--Constantly count down on the cooldown timer
	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	--Begin drawing the bow
	if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.drawTimer > 0 or not status.resourceLocked("energy")) then
		self:setState(self.draw)
	end

	--Debug Variables
	world.debugPoint(self:firePosition(), "red")
	if self.predictedPosition then
		world.debugPoint(self.predictedPosition, "yellow")
	end
end
function NebRNGAimBot:reset()
	activeItem.setScriptedAnimationParameter("entities", {})
	self.targets = {}
	animator.setGlobalTag("drawFrame", "0")
	animator.setAnimationState("bow", "idle")
	animator.stopAllSounds("draw")
	animator.stopAllSounds("ready")
	self.weapon:setStance(self.stances.idle)
end

function NebRNGAimBot:draw()
	self.weapon:setStance(self.stances.draw)

	animator.playSound("draw", -1)
	local readySoundPlayed = false

	while self.fireMode == (self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") do
		if self.walkWhileFiring then
			mcontroller.controlModifiers({runningSuppressed = true})
		end

		self.targets = util.filter(self.targets, world.entityExists)
		if #self.targets < self.maxTargets then
			local newTarget = self:findTarget()
			if newTarget and status.overConsumeResource("energy", self.holdEnergyUsage) then
				table.insert(self.targets, newTarget)
				animator.playSound("targetAcquired"..#self.targets)

				activeItem.setScriptedAnimationParameter("entities", self.targets)
			else
				self.predictedPosition = nil
				activeItem.setScriptedAnimationParameter("entities", {})
			end
		end

		local aimVec = self:idealAimVector()
		local firePosition = self:firePosition()
		if self.aimOutOfReach or self.aimTypeSwitchTimer > 0 then
			local aimAngle = activeItem.aimAngleAndDirection(self.weapon.aimOffset, activeItem.ownerAimPosition())
			self.weapon.aimAngle = aimAngle

			world.debugLine(firePosition, vec2.add(firePosition, vec2.mul(vec2.norm(self:idealAimVector()), 3)), "yellow")
		elseif self.targets and self.targets[1] then
			self.weapon.stance.allowRotate = false
			self.weapon.stance.allowFlip = false
			aimVec[1] = aimVec[1] * self.directionToTarget
			self.weapon.aimDirection = self.directionToTarget
			self.weapon.aimAngle = vec2.angle(aimVec)

			world.debugLine(firePosition, vec2.add(firePosition, vec2.mul(vec2.norm(self:idealAimVector()), 3)), "green")
		else
			self.weapon.stance.allowRotate = true
			self.weapon.stance.allowFlip = true
		end

		--Code for calculating which cursor to use
		--In the while loop to avoid conflict with primary
		if not self.hasChargedCursor then
			local cursorFrame = math.max(math.ceil(self.drawTimer * #self.cursorFrames), 1)
			activeItem.setCursor(self.cursorFrames[cursorFrame])
			if cursorFrame == #self.cursorFrames then
				self.hasChargedCursor = true
			end
		else
			activeItem.setCursor(self.cursorFrames[#self.cursorFrames])
		end

		self.drawTimer = self.drawTimer + self.dt

		local drawFrame = math.min(#self.drawArmFrames - 2, math.floor(self.drawTimer / self.drawTime * (#self.drawArmFrames - 1)))

		--If not yet fully drawn, drain energy quickly
		if self.drawTimer < self.drawTime then
			status.overConsumeResource("energy", self.energyPerShot / self.drawTime * self.dt)

		--If fully drawn and at peak power, prevent energy regen and set the drawFrame to power charged
		elseif self.drawTimer > self.drawTime and self.drawTimer <= (self.drawTime + (self.powerProjectileTime or 0)) then
			status.setResourcePercentage("energyRegenBlock", 0.6)
			drawFrame = #self.drawArmFrames - 1
			if self.drainEnergyWhilePowerful then
				status.overConsumeResource("energy", self.holdEnergyUsage * self.dt) --Optionally drain energy while at max power level
			end

		--If drawn beyond power peak levels, drain energy slowly
		elseif self.drawTimer > (self.drawTime + (self.powerProjectileTime or 0)) then
			status.overConsumeResource("energy", self.holdEnergyUsage * self.dt)
		end
		--If the bow is almost fully drawn, stop the draw sound and play the ready sound
		--Do this slightly before the draw is ready so the player can release when they hear the sound
		--This way, the sound plays at the same moment in the draw phase for every bow regardless of draw time
		if self.drawTimer >= (self.drawTime - 0.15) then
			animator.stopAllSounds("draw")
			if not readySoundPlayed then
				animator.playSound("ready")
				readySoundPlayed = true
			end
		end

		animator.setGlobalTag("drawFrame", drawFrame)

		if drawFrame == 5 then --or whatever the frame is
			animator.setGlobalTag("directives", "?fade=FFFFFFFF=0.1")
			--sb.logInfo("jim charle here")
		else
			animator.setGlobalTag("directives", "")
		end

		self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

		--world.debugText(drawFrame .. " | " .. sb.printJson(self:perfectTiming()), mcontroller.position(), "red")
		--world.debugText(sb.printJson(self:currentProjectileParameters(), 1), mcontroller.position(), "yellow")
		--self:currentProjectileParameters()
		coroutine.yield()
	end

	animator.stopAllSounds("draw")
	self:setState(self.fire)
end

function NebRNGAimBot:fire()
	self.hasChargedCursor = false
	activeItem.setCursor(self.cursorFrames[1])
	self.weapon:setStance(self.stances.fire)

	animator.setGlobalTag("drawFrame", "0")
	animator.setGlobalTag("directives", "")
	animator.stopAllSounds("ready")

	if not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if self.drawTimer > (self.drawTime + (self.powerProjectileTime or 0)) then
			if self.elementalType ~= "physical" then
				self.projectileParameters.damageKind = self.elementalType .. "bow"
			end
			self.projectileParameters.periodicActions = {
				{
					time = 0,
					action = "projectile",
					type = self.elementalType .. "arrowenergy",
					angleAdjust = 0,
					config = {timeToLive = 0},
					inheritDamageFactor = 0.0,
					inheritSpeedFactor = 1
				}
			}
		end
		for _ = 1, (self.projectileCount or 1) do
			world.spawnProjectile(
				self:perfectTiming() and self.powerProjectileType or self.altProjectileType,
				self:firePosition(),
				activeItem.ownerEntityId(),
				self:idealAimVector(),
				false,
				self:currentProjectileParameters()
			)

			if self:perfectTiming() then
				animator.playSound("perfectRelease")
			else
				animator.playSound("release")
			end
		end

		animator.setAnimationState("bow", "loosed")

		self.drawTimer = 0

		util.wait(self.stances.fire.duration)
	else
		animator.setGlobalTag("drawFrame", "0")
	end

	self.projectileParameters.periodicActions = nil
	self.cooldownTimer = self.cooldownTime
	self.predictedPosition = nil
	animator.setGlobalTag("directives", "")
end

--Call this to check if the bow was released at the perfect moment. Bows can be configured to not use perfect timing mechanics
function NebRNGAimBot:perfectTiming()
	if self.powerProjectileTime then
		return self.drawTimer > self.drawTime and self.drawTimer < (self.drawTime + self.powerProjectileTime)
	else
		return false
	end
end

function NebRNGAimBot:currentProjectileParameters()
	self.projectileGravityMultiplier = root.projectileGravityMultiplier(self.powerProjectileType or self.altProjectileType)

	local arrowVariant = self.arrowVariant.arrow:match("(%d+)%.png")
	--Set projectile parameters based on draw power level
	local projectileParameters = copy(self:perfectTiming() and self.powerProjectileParameters or self.projectileParameters or {})
	--Load the root projectile config based on draw power level
	local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.altProjectileType)

	local speedMultiplier = 1.0
	if self.minMaxSpeedMultiplier then
		speedMultiplier = math.random(self.minMaxSpeedMultiplier[1] * 100, self.minMaxSpeedMultiplier[2] * 100) / 100
	end

	--Calculate projectile speed based on draw time and projectile parameters
	projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
	projectileParameters.speed = projectileParameters.speed * math.min(1, (self.drawTimer / self.drawTime)) * speedMultiplier

	self.projectileSpeed = projectileParameters.speed or projectileConfig.speed

	projectileParameters.processing = self.paletteSwaps

	if self.altProjectileType == "rngbouncingarrow" then
		self.projectileParameters.actionOnReap = nil
	else
		self.projectileParameters.actionOnReap = {
			{
				action = "projectile",
				type = "arrow" .. arrowVariant .. "sticking",
				angleAdjust = 0,
				config = {processing = self.paletteSwaps},
				inheritDamageFactor = 0.1,
				inheritSpeedFactor = 0.6
			}
		}
	end

	--Bonus damage calculation for quiver users
	local damageBonus = 1.0
	if self.useQuiverDamageBonus == true and status.statPositive("RNGdamageQuiver") then
		damageBonus = status.stat("RNGdamageQuiver")
	end

	--Calculate projectile power based on draw time and projectile parameters
	local drawTimeMultiplier = self.staticDamageMultiplier or math.min(1, (self.drawTimer / self.drawTime))
	projectileParameters.power = projectileParameters.power or projectileConfig.power
	projectileParameters.power = projectileParameters.power
		* self.drawTime
		* self.weapon.damageLevelMultiplier
		* drawTimeMultiplier
		* (self.dynamicDamageMultiplier or 1)
		* damageBonus
		* (mcontroller.onGround() and 1 or self.airborneBonus)
		/ (self.projectileCount or 1)
	projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()

	return projectileParameters
end

function NebRNGAimBot:idealAimVector(inaccuracy)
	--Register enemy targeting data
	local firePosition = self:firePosition()
	if self.targets and self.targets[1] then
		local target = self.targets[1]
		local targetDistance = world.distance(world.entityMouthPosition(target), firePosition)
		local targetMagnitude = world.magnitude(firePosition, world.entityMouthPosition(target))
		self.directionToTarget = util.toDirection(targetDistance[1])
		if targetMagnitude >= 1 then
			local targetVelocity = world.entityVelocity(target)
			-- Essential to calculate the projectile speed
			self:currentProjectileParameters()
			local estimatedArivalTime = targetMagnitude / self.projectileSpeed

			self.predictedPosition = vec2.add(targetDistance, vec2.mul(targetVelocity, estimatedArivalTime))
		elseif targetMagnitude <= 1 then
			self.predictedPosition = world.entityMouthPosition(target)
		end
	else
		local cursorDistance = world.distance(activeItem.ownerAimPosition(), firePosition)
		self.directionToTarget = cursorDistance[1] / math.abs(cursorDistance[1])
	end

	self.aimOutOfReach = true
	--If we are at a zero G position, use regular aiming instead of arc-adjusted aiming
	if mcontroller.zeroG() then
		local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
		aimVector[1] = aimVector[1] * mcontroller.facingDirection()
		self.aimTypeSwitchTimer = 0.1 --Hold the last aiming type for a brief moment to smooth transitions
		return aimVector
	else
		local targetOffset = world.distance(activeItem.ownerAimPosition(), firePosition)

		--Code taken from util.lua to determine when the aim position is out of range
		local x = targetOffset[1]
		local y = targetOffset[2]
		local g = self.projectileGravityMultiplier * world.gravity(mcontroller.position())
		local v = self.projectileParameters.speed
		if g < 0 then
			g = -g
			y = -y
		end
		local term1 = v^4 - (g * ((g * x * x) + (2 * y * v * v)))

		if term1 > 0 then
			self.aimOutOfReach = false
			return util.aimVector(self.predictedPosition or targetOffset, self.projectileParameters.speed, self.projectileGravityMultiplier, false)
		else
			local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
			aimVector[1] = aimVector[1] * mcontroller.facingDirection()
			self.aimTypeSwitchTimer = 0.1 --Hold the last aiming type for a brief moment to smooth transitions
			return aimVector
		end
	end
end

function NebRNGAimBot:findTarget()
	local nearEntities = world.entityQuery(activeItem.ownerAimPosition(), self.targetQueryDistance, { includedTypes = {"monster", "npc", "player"} })
	nearEntities = util.filter(nearEntities,
		function(entityId)
			if contains(self.targets, entityId) then
				return false
			end

			if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
				return false
			end

			if world.lineTileCollision(self:firePosition(), world.entityPosition(entityId)) then
				return false
			end

			return true
		end
	)

	if #nearEntities > 0 then
		return nearEntities[1]
	else
		return false
	end
end

function NebRNGAimBot:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function NebRNGAimBot:uninit()
	self:reset()
end

