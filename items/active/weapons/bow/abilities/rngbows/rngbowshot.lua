--Modified bow shot ability that drains energy while drawing and holding, with configurable drain rates. Has an animation state for when arrows have been loosed
require "/scripts/vec2.lua"
require "/items/active/weapons/crits.lua"

-- Bow primary ability
NebRNGBowShot = WeaponAbility:new()

function NebRNGBowShot:init()
	self.energyPerShot = self.energyPerShot or 0
	animator.setGlobalTag("directives", config.getParameter("directives", ""))
	self.paletteSwaps = config.getParameter("paletteSwaps")
	self.elementalType = config.getParameter("elementalType")
	self.arrowVariant = config.getParameter("animationParts")

	self.drawTimer=0
	self.baseDrawTime=self.drawTime
	self.modifiedDrawTime = math.max(script.updateDt(),self.baseDrawTime*(1/(1+math.max(-0.99,status.stat("bowDrawTimeBonus")))))
    
	animator.setAnimationState("bow", "idle")
	self.cooldownTimer = 0

	self:reset()

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function NebRNGBowShot:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	world.debugPoint(self:firePosition(), "red")

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	--Code for calculating which cursor to use
	if not self.hasChargedCursor then
		local cursorFrame = math.max(math.ceil(self.drawTimer* #self.cursorFrames), 1)
		activeItem.setCursor(self.cursorFrames[cursorFrame])
		if cursorFrame == #self.cursorFrames then
			self.hasChargedCursor = true
		end
	else
		activeItem.setCursor(self.cursorFrames[#self.cursorFrames])
	end

	if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.drawTimer> 0 or not status.resourceLocked("energy")) then
		self:setState(self.draw)
	end
end

function NebRNGBowShot:uninit()
	self:reset()
end

function NebRNGBowShot:reset()
	animator.setGlobalTag("drawFrame", "0")
	animator.setAnimationState("bow", "idle")
	animator.stopAllSounds("draw")
	animator.stopAllSounds("ready")
	self.weapon:setStance(self.stances.idle)
	status.setStatusProperty(activeItem.hand().."Firing",nil)
end

function NebRNGBowShot:draw()
	self.energyBonus = status.stat("bowEnergyBonus")

	self.weapon:setStance(self.stances.draw)

	animator.setSoundPitch("draw", 1, self.modifiedDrawTime)
	animator.playSound("draw", -1)
	local readySoundPlayed = false

	status.setStatusProperty(activeItem.hand().."Firing",true)
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") do
		if self.walkWhileFiring then
			mcontroller.controlModifiers({runningSuppressed = true})
		end

		self.drawTimer= self.drawTimer+ self.dt

		local drawFrame = math.min(#self.drawArmFrames - 2, math.floor(self.drawTimer/ self.modifiedDrawTime * (#self.drawArmFrames - 1)))

		--If not yet fully drawn, drain energy quickly
		if self.drawTimer< self.modifiedDrawTime then
			status.overConsumeResource("energy", (self.energyPerShot - self.energyBonus) / self.modifiedDrawTime * self.dt)

		--If fully drawn and at peak power, prevent energy regen and set the drawFrame to power charged
		elseif self.drawTimer> self.modifiedDrawTime and self.drawTimer<= (self.modifiedDrawTime + (self.powerProjectileTime or 0)) then
			status.setResourcePercentage("energyRegenBlock", 0.6)
			drawFrame = #self.drawArmFrames - 1
			if self.drainEnergyWhilePowerful then
			status.overConsumeResource("energy", self.holdEnergyUsage * self.dt) --Optionally drain energy while at max power level
			end

		--If drawn beyond power peak levels, drain energy slowly
		elseif self.drawTimer> (self.modifiedDrawTime + (self.powerProjectileTime or 0)) then
			status.overConsumeResource("energy", self.holdEnergyUsage * self.dt)
		end
		--If the bow is almost fully drawn, stop the draw sound and play the ready sound
		--Do this slightly before the draw is ready so the player can release when they hear the sound
		--This way, the sound plays at the same moment in the draw phase for every bow regardless of draw time
		if self.drawTimer>= (self.modifiedDrawTime - 0.15) then
			animator.stopAllSounds("draw")
			if not readySoundPlayed then
			animator.playSound("ready")
			readySoundPlayed = true
			end
		end

		animator.setGlobalTag("drawFrame", drawFrame)

		if drawFrame == 5 then
			animator.setGlobalTag("directives", "?fade=FFFFFFFF=0.1")
		else
			animator.setGlobalTag("directives", "")
		end

		self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

		--Debug Variables
		world.debugText(drawFrame .. " | " .. sb.printJson(self:perfectTiming()), mcontroller.position(), "red")
		world.debugText(sb.printJson(self:currentProjectileParameters(), 1), mcontroller.position(), "yellow")

		coroutine.yield()
	end

	animator.stopAllSounds("draw")
	self:setState(self.fire)
end

function NebRNGBowShot:fire()
	self.hasChargedCursor = false
	activeItem.setCursor(self.cursorFrames[1])
	self.weapon:setStance(self.stances.fire)

	animator.setGlobalTag("drawFrame", "0")
	animator.setGlobalTag("directives", "")
	animator.stopAllSounds("ready")

	if not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		local projectileParameters = copy(self:perfectTiming() and self.powerProjectileParameters or self.projectileParameters or {})
		if self.drawTimer> (self.modifiedDrawTime + (self.powerProjectileTime or 0)) then
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
			for i = 1, (self.projectileCount or 1) do
				world.spawnProjectile(
					self:perfectTiming() and self.powerProjectileType or self.projectileType,
					self:firePosition(),
					activeItem.ownerEntityId(),
					self:aimVector(),
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

		self.drawTimer= 0

		util.wait(self.stances.fire.duration)
	else
		animator.setGlobalTag("drawFrame", "0")
	end

	self.projectileParameters.periodicActions = nil
	self.cooldownTimer = self.cooldownTime
	animator.setGlobalTag("directives", "")
	status.setStatusProperty(activeItem.hand().."Firing",false)
end

--Call this to check if the bow was released at the perfect moment. Bows can be configured to not use perfect timing mechanics
function NebRNGBowShot:perfectTiming()
	if self.powerProjectileTime then
		return self.drawTimer> self.modifiedDrawTime and self.drawTimer< (self.modifiedDrawTime + self.powerProjectileTime)
	else
		return false
	end
end

function NebRNGBowShot:currentProjectileParameters()
	local arrowVariant = self.arrowVariant.arrow:match("(%d+)%.png")
	--Set projectile parameters based on draw power level
	local projectileParameters = copy(self:perfectTiming() and self.powerProjectileParameters or self.projectileParameters or {})
	--Load the root projectile config based on draw power level
	local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.projectileType)

	local speedMultiplier = 1.0
	if self.minMaxSpeedMultiplier then
		speedMultiplier = math.random(self.minMaxSpeedMultiplier[1] * 100, self.minMaxSpeedMultiplier[2] * 100) / 100
	end
	speedMultiplier = speedMultiplier*(1+status.stat("arrowSpeedMultiplier"))

	--Calculate projectile speed based on draw time and projectile parameters
	projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
	projectileParameters.speed = projectileParameters.speed * math.min(1, (self.drawTimer/ self.modifiedDrawTime)) * speedMultiplier

	projectileParameters.processing = self.paletteSwaps

	if self.projectileType == "rngbouncingarrow" then
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
	if self.useQuiverDamageBonus == true and status.statPositive("nebsrngbowdamagebonus") then
		damageBonus = damageBonus+status.stat("nebsrngbowdamagebonus")
	end

	--Calculate projectile power based on draw time and projectile parameters
	local drawTimeMultiplier = self.staticDamageMultiplier or math.min(1, (self.drawTimer/ self.modifiedDrawTime))
	projectileParameters.power = projectileParameters.power or projectileConfig.power
	projectileParameters.power = projectileParameters.power
		* self.modifiedDrawTime
		* self.weapon.damageLevelMultiplier
		* drawTimeMultiplier
		* (self.dynamicDamageMultiplier or 1)
		* damageBonus
		* ((mcontroller.onGround() and 1) or ((mcontroller.liquidMovement() and 1) or (mcontroller.zeroG() and 1) or (self.airborneBonus + status.stat("bowAirBonus"))))
		/ (self.projectileCount or 1)
		projectileParameters.power = Crits.setCritDamage(self,projectileParameters.power)
		projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()
	return projectileParameters
end

function NebRNGBowShot:aimVector()
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
	aimVector[1] = aimVector[1] * self.weapon.aimDirection
	return aimVector
end

function NebRNGBowShot:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end
