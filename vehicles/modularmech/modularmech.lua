require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	message.setHandler("despawnMech", despawn)
	--message.setHandler("sendMechHazardData",function(...) return copy(self.hazardImmunityList) end)
	message.setHandler("currentEnergy", function()
		if not alive() then
			return 0
		end

		return storage.energy / self.energyMax
	end)

	message.setHandler("currentHealth", function()
		if not alive() then
			return 0
		end

		return storage.health / self.healthMax
	end)

	message.setHandler("restoreEnergy", function(_, _, base, percentage)
		if alive() then
			setEnergyValue()
			local restoreAmount = (base or 0) + self.energyMax * (percentage or 0)
			if storage.energy < self.energyMax then
				storage.energy = storage.energy + (restoreAmount*0.75)
				if self.driverId and world.entityType(self.driverId) == "player" then
					world.sendEntityMessage(self.ownerEntityId, "setQuestFuelCount", storage.energy + (restoreAmount * 0.15))
				end
			end
			animator.playSound("restoreEnergy")
		end
	end)

	message.setHandler("restoreHealth", function(_, _, base, percentage)
		if alive() then
			setHealthValue()
			local restoreAmount = (base or 0) + self.healthMax * (percentage or 0)
			storage.health = math.min(storage.health + (restoreAmount*0.75), self.healthMax)

			animator.playSound("restoreEnergy")
			if storage.health > self.healthMax then
				storage.health = self.healthMax
			end
		end
	end)

	self.ownerUuid = config.getParameter("ownerUuid")
	self.ownerEntityId = config.getParameter("ownerEntityId")

	-- initialize configuration parameters

	self.movementSettings = config.getParameter("movementSettings")
	self.walkingMovementSettings = config.getParameter("walkingMovementSettings")
	self.flyingMovementSettings = config.getParameter("flyingMovementSettings")

	-- common (not from parts) config

	self.damageFlashTimer = 0
	self.damageFlashTime = config.getParameter("damageFlashTime")
	self.damageFlashDirectives = config.getParameter("damageFlashDirectives")

	self.jumpBoostTimer = 0

	self.fallThroughTimer = 0
	self.fallThroughTime = config.getParameter("fallThroughTime")
	self.fallThroughSustain = false

	self.onGroundTimer = 0
	self.onGroundTime = config.getParameter("onGroundTime")

	self.frontFoot = config.getParameter("frontFootOffset")
	self.backFoot = config.getParameter("backFootOffset")
	self.footCheckXOffsets = config.getParameter("footCheckXOffsets")

	self.legRadius = config.getParameter("legRadius")
	self.legVerticalRatio = config.getParameter("legVerticalRatio")
	self.legCycle = 0.25
	self.reachGroundDistance = config.getParameter("reachGroundDistance")

	self.flightLegOffset = config.getParameter("flightLegOffset")

	self.stepSoundLimitTime = config.getParameter("stepSoundLimitTime")
	self.stepSoundLimitTimer = 0

	self.walkBobMagnitude = config.getParameter("walkBobMagnitude")

	self.landingBobMagnitude = config.getParameter("landingBobMagnitude")
	self.landingBobTime = config.getParameter("landingBobTime")
	self.landingBobTimer = 0
	self.landingBobThreshold = config.getParameter("landingBobThreshold")

	self.boosterBobDelay = config.getParameter("boosterBobDelay")
	self.armBobDelay = config.getParameter("armBobDelay")

	self.armFlipOffset = config.getParameter("armFlipOffset")

	self.flightOffsetFactor = config.getParameter("flightOffsetFactor")
	self.flightOffsetClamp = config.getParameter("flightOffsetClamp")
	self.currentFlightOffset = {0, 0}

	self.boostDirection = {0, 0}

	self.despawnTime = config.getParameter("despawnTime")
	self.explodeTime = config.getParameter("explodeTime")
	self.explodeProjectile = config.getParameter("explodeProjectile")

	self.materialKind = "robotic"

	-- set part image tags

	self.partImages = config.getParameter("partImages")

	for k, v in pairs(self.partImages) do
		animator.setPartTag(k, "partImage", v)
	end

	-- set part directives

	self.partDirectives = config.getParameter("partDirectives")

	for k, v in pairs(self.partDirectives) do
		animator.setGlobalTag(k .. "Directives", v)
	end

	-- setup part functional config

	self.parts = config.getParameter("parts")

	-- setup body

	self.protection = self.parts.body.protection

	-- setup boosters

	self.airControlSpeed = self.parts.booster.airControlSpeed
	self.airControlForce = self.parts.booster.airControlForce
	self.flightControlSpeed = self.parts.booster.flightControlSpeed
	self.flightControlForce = self.parts.booster.flightControlForce

	-- setup legs

	self.groundSpeed = self.parts.legs.groundSpeed
	self.groundControlForce = self.parts.legs.groundControlForce
	self.jumpVelocity = self.parts.legs.jumpVelocity
	self.jumpAirControlSpeed = self.parts.legs.jumpAirControlSpeed
	self.jumpAirControlForce = self.parts.legs.jumpAirControlForce
	self.jumpBoostTime = self.parts.legs.jumpBoostTime

	-- setup arms

	--FU special stats from modules
	self.aimassist = self.parts.hornName == 'mechaimassist'
	self.masspassive = self.parts.hornName == 'mechchipfeather'
	self.masscancel = self.parts.hornName == 'mechmasscancel' or self.parts.hornName == 'mechmasscancel2' or self.parts.hornName == 'mechmasscancel3' or self.parts.hornName == 'mechmasscancel4'
	self.defenseboost = self.parts.hornName == 'mechdefensefield' or self.parts.hornName == 'mechdefensefield2' or self.parts.hornName == 'mechdefensefield3' or self.parts.hornName == 'mechdefensefield4' or self.parts.hornName == 'mechdefensefield5'
	self.energyboost = self.parts.hornName == 'mechenergyfield' or self.parts.hornName == 'mechenergyfield2' or self.parts.hornName == 'mechenergyfield3' or self.parts.hornName == 'mechenergyfield4' or self.parts.hornName == 'mechenergyfield5'
	self.mobilityboost = self.parts.hornName == 'mechchipspeed' or self.parts.hornName == 'mechchipcontrol' or self.parts.hornName == 'mechmobility' or self.parts.hornName == 'mechmobility2' or self.parts.hornName == 'mechmobility3' or self.parts.hornName == 'mechmobility4' or self.parts.hornName == 'mechmobility5'
	self.fuelboost = self.parts.hornName == 'mechchipfuel' or self.parts.hornName == 'mechchiprefueler' or self.parts.hornName == 'mechchipovercharge'
	self.otherboost = self.parts.hornName == 'mechchipdefense'	or self.parts.hornName == 'mechchippower'
	self.mobilityBoostValue = 0
	self.mobilityControlValue = 0
	self.mobilityJumpValue = 0
	self.fuelCost = 1
	self.fuelBoost = 0

	--
	require(self.parts.leftArm.script)
	self.leftArm = _ENV[self.parts.leftArm.armClass]:new(self.parts.leftArm, "leftArm", {2.375, 2.0}, self.ownerUuid)

	require(self.parts.rightArm.script)
	self.rightArm = _ENV[self.parts.rightArm.armClass]:new(self.parts.rightArm, "rightArm", {-2.375, 2.0}, self.ownerUuid)

	-- setup energy pool --modded
	--set up health pool
	setHealthValue()
	storage.health = storage.health or (config.getParameter("startHealthRatio", 1.0) * self.healthMax)

	--self.energyMax = self.parts.body.energyMax
	self.energyMax =((100 + self.parts.body.energyMax)*(self.parts.body.stats.energyBonus or 1)) + (self.energyBoost or 0)
	storage.energy = storage.energy or (config.getParameter("startEnergyRatio", 1.0) * self.energyMax)

	self.energyDrain = self.parts.body.energyDrain + (self.parts.leftArm.energyDrain or 0) + (self.parts.rightArm.energyDrain or 0)
	self.energyDrain = self.energyDrain*0.2

	--factor Mass into energy drain, as a penalty
	self.massTotal = (self.parts.body.stats.mechMass or 0) + (self.parts.booster.stats.mechMass or 0) + (self.parts.legs.stats.mechMass or 0) + (self.parts.leftArm.stats.mechMass or 0) + (self.parts.rightArm.stats.mechMass or 0)

	self.massMod = self.massTotal/200

	--factor in module bonus/penalty
	self.energyDrain = (self.energyDrain * (1 + self.massMod)) * (self.fuelCost or 1)
	--end
    self.healthDrain = 0

	-- check for environmental hazards / protection

	local hazards = config.getParameter("hazardVulnerabilities")
	--self.hazardImmunityList={}
	for _, statusEffect in pairs(self.parts.body.hazardImmunities or {}) do
		hazards[statusEffect] = nil
		--self.hazardImmunityList[statusEffect]=true
	end


	local applyEnvironmentStatuses = config.getParameter("applyEnvironmentStatuses")
	local seatStatusEffects = config.getParameter("loungePositions.seat.statusEffects")

	for _, statusEffect in pairs(world.environmentStatusEffects(mcontroller.position())) do
		if hazards[statusEffect] then
			self.regenPenalty = hazards[statusEffect].energyDrain or 0 -- Mechs can have regen, but not if they are in hostile environs.
			self.energyDrain = self.energyDrain + hazards[statusEffect].energyDrain  --increased energy use in uncertified environments
			self.healthDrain = 0.1 --health also gets penalized when on these worlds. Apply a base decrement of 0.1, and modify in update()
			world.sendEntityMessage(self.ownerEntityId, "queueRadioMessage", hazards[statusEffect].message, 1.5)
		end

		for _, applyEffect in ipairs(applyEnvironmentStatuses) do
			if statusEffect == applyEffect then
				table.insert(seatStatusEffects, statusEffect)
			end
		end
	end

	vehicle.setLoungeStatusEffects("seat", seatStatusEffects)

	self.liquidVulnerabilities = config.getParameter("liquidVulnerabilities")

	-- initialize persistent and last frame state data
	self.facingDirection = 1
	self.lastWalking = false
	self.lastPosition = mcontroller.position()
	self.lastVelocity = mcontroller.velocity()
	self.lastOnGround = mcontroller.onGround()

	self.lastControls = {
		left = false,
		right = false,
		up = false,
		down = false,
		jump = false,
		PrimaryFire = false,
		AltFire = false,
		Special1 = false
	}

	setFlightMode(world.gravity(mcontroller.position()) == 0)

	message.setHandler("deploy", function()
		self.deploy = config.getParameter("deploy")
		self.deploy.fadeTime = self.deploy.fadeInTime + self.deploy.fadeOutTime

		self.deploy.fadeTimer = self.deploy.fadeTime
		self.deploy.deployTimer = self.deploy.deployTime
		mcontroller.setVelocity({0, self.deploy.initialVelocity})
	end)

	--manual flight mode
	self.manualFlightMode = false;
	self.doubleJumpCount = 0
	self.doubleJumpDelay = 0

	self.crouch = 0.0 -- 0.0 ~ 1.0
	self.crouchTarget = 0.0

	self.crouchCheckMax = 7.0
	self.bodyCrouchMax = -2.0
	-- self.crouchCheckMax = 20.0
	-- self.bodyCrouchMax = -4.0
	self.hipCrouchMax = 2.0

	self.crouchSettings = config.getParameter("crouchSettings")
	self.noneCrouchSettings = config.getParameter("noneCrouchSettings")

	self.doubleTabBoostOn = false
	self.doubleTabBoostDirection = "null"
	self.doubleTabCount = 0
	self.doubleTabCheckDelay = 0.0
	self.doubleTabCheckDelayTime = 0.3
	self.doubleTabBoostCrouchTargetTo = 0.15
	self.doubleTabBoostSpeedMultTarget = 3.0
	self.doubleTabBoostSpeedMult = 1.0

	self.doubleTabBoostJump = false
end

function setDefenseBoostValue()
	self.defenseboost = self.parts.hornName == 'mechdefensefield' or self.parts.hornName == 'mechdefensefield2' or self.parts.hornName == 'mechdefensefield3' or self.parts.hornName == 'mechdefensefield4' or self.parts.hornName == 'mechdefensefield5'
	if self.defenseboost then
		if self.parts.hornName == 'mechdefensefield' then
			self.defenseBoost = 50
		elseif self.parts.hornName == 'mechdefensefield2' then
			self.defenseBoost = 100
		elseif self.parts.hornName == 'mechdefensefield3' then
			self.defenseBoost = 150
		elseif self.parts.hornName == 'mechdefensefield4' then
			self.defenseBoost = 200
		elseif self.parts.hornName == 'mechdefensefield5' then
			self.defenseBoost = 250
		end
	else
		self.defenseBoost = 0
	end
end

function setEnergyBoostValue()
	self.energyboost = self.parts.hornName == 'mechenergyfield' or self.parts.hornName == 'mechenergyfield2' or self.parts.hornName == 'mechenergyfield3' or self.parts.hornName == 'mechenergyfield4' or self.parts.hornName == 'mechenergyfield5'
	if self.energyboost then
		if self.parts.hornName == 'mechenergyfield' then
			self.energyBoost = 50
		elseif self.parts.hornName == 'mechenergyfield2' then
			self.energyBoost = 100
		elseif self.parts.hornName == 'mechenergyfield3' then
			self.energyBoost = 150
		elseif self.parts.hornName == 'mechenergyfield4' then
			self.energyBoost = 200
		elseif self.parts.hornName == 'mechenergyfield5' then
			self.energyBoost = 250
		end
	else
		self.energyBoost = 0
	end
end

function setMobilityBoostValue()
	self.mobilityboost = self.parts.hornName == 'mechchipspeed' or self.parts.hornName == 'mechchipcontrol' or self.parts.hornName == 'mechmobility' or self.parts.hornName == 'mechmobility2' or self.parts.hornName == 'mechmobility3' or self.parts.hornName == 'mechmobility4' or self.parts.hornName == 'mechmobility5'
	if self.mobilityboost then
		if self.parts.hornName == 'mechmobility' then
			self.mobilityBoostValue = 1.1
			self.mobilityControlValue = 1.1
			self.mobilityJumpValue = 1
		elseif self.parts.hornName == 'mechmobility2' then
			self.mobilityBoostValue = 1.2
			self.mobilityControlValue = 1.2
			self.mobilityJumpValue = 1
		elseif self.parts.hornName == 'mechmobility3' then
			self.mobilityBoostValue = 1.3
			self.mobilityControlValue = 1.3
			self.mobilityJumpValue = 1
		elseif self.parts.hornName == 'mechmobility4' then
			self.mobilityBoostValue = 1.4
			self.mobilityControlValue = 1.4
			self.mobilityJumpValue = 1
		elseif self.parts.hornName == 'mechmobility5' then
			self.mobilityBoostValue = 1.5
			self.mobilityControlValue = 1.5
			self.mobilityJumpValue = 1
		elseif self.parts.hornName == 'mechchipcontrol' then
			self.mobilityBoostValue = 0.8
			self.mobilityControlValue = 1.4
			self.mobilityJumpValue = 1.2
		elseif self.parts.hornName == 'mechchipspeed' then
			self.mobilityBoostValue = 1.2
			self.mobilityControlValue = 0.8
			self.mobilityJumpValue = 0.8
		end
	else
		self.mobilityBoostValue = 1
		self.mobilityControlValue = 1
		self.mobilityJumpValue = 1
	end
end

function setMassBoostValue()
 	self.masspassive = self.parts.hornName == 'mechchipfeather'
	if self.fuelboost then
		if self.parts.hornName == 'mechchipfeather' then --we'll calculate Feather here
			self.mechMass = self.mechMass * 0.4
			self.defenseBoost = self.defenseBoost * 0.75
		end
	end
end

function setFuelBoostValue()
 	self.fuelboost = self.parts.hornName == 'mechchipfuel'	or self.parts.hornName == 'mechchiprefueler' or self.parts.hornName == 'mechchipovercharge'
	if self.fuelboost then
		if self.parts.hornName == 'mechchipfuel' then
			self.healthMax = self.healthMax * 0.8
			self.energyBoost = 200
		elseif self.parts.hornName == 'mechchiprefueler' then
			self.fuelCost = 0.6
		elseif self.parts.hornName == 'mechchipovercharge' then
			self.fuelCost = 2.5
			self.mobilityBoostValue = 1.8
		end
	end
end

function setHealthValue()
	self.massTotal = (self.parts.body.stats.mechMass or 0) + (self.parts.booster.stats.mechMass or 0) + (self.parts.legs.stats.mechMass or 0) + (self.parts.leftArm.stats.mechMass or 0) + (self.parts.rightArm.stats.mechMass or 0)
	setDefenseBoostValue()
	self.defenseModifier = self.defenseBoost + (self.massTotal*2)
	setMassBoostValue()
	self.healthMax = ((((150 * (self.parts.body.stats.healthBonus or 1)) + self.massTotal) * self.parts.body.stats.protection) + (self.defenseModifier or 0) )
	setMobilityBoostValue() --set other boosts while we are at it
	setFuelBoostValue() --set other boosts while we are at it
end

function totalMass()
  self.massTotal = (self.parts.body.stats.mechMass or 0) + (self.parts.booster.stats.mechMass or 0) + (self.parts.legs.stats.mechMass or 0) + (self.parts.leftArm.stats.mechMass or 0) + (self.parts.rightArm.stats.mechMass or 0)
end

function setEnergyValue()
	self.massTotal = (self.parts.body.stats.mechMass or 0) + (self.parts.booster.stats.mechMass or 0) + (self.parts.legs.stats.mechMass or 0) + (self.parts.leftArm.stats.mechMass or 0) + (self.parts.rightArm.stats.mechMass or 0)
	setEnergyBoostValue()
	if self.massTotal > 22 then
		self.energyBoost = self.energyBoost * (self.massTotal/50)
	end
	self.energyMax = ((50 + self.parts.body.energyMax)*(self.parts.body.stats.energyBonus or 1)) + (self.energyBoost or 0)
end

-- this function activates all the relevant stats that FU needs to call on for mech parts
-- **************************************************************************************
function activateFUMechStats()
		self.mechBonusBody = self.parts.body.stats.protection + self.parts.body.stats.energy
		self.mechBonusBooster = self.parts.booster.stats.control + self.parts.booster.stats.speed
		self.mechBonusLegs = self.parts.legs.stats.speed + self.parts.legs.stats.jump
		self.mechBonusTotal = self.mechBonusLegs + self.mechBonusBooster + self.mechBonusBody -- all three combined

		-- Failsafe to make certain there is never a nil value for mech part mass
		if not self.parts.body.stats.mechMass then self.parts.body.stats.mechMass = 0 end
		if not self.parts.booster.stats.mechMass then self.parts.booster.stats.mechMass = 0 end
		if not self.parts.legs.stats.mechMass then self.parts.legs.stats.mechMass = 0 end
		if not self.parts.leftArm.stats.mechMass then self.parts.leftArm.stats.mechMass = 0 end
		if not self.parts.rightArm.stats.mechMass then self.parts.rightArm.stats.mechMass = 0 end

		--compute mech mass here
		self.mechMass = self.parts.body.stats.mechMass + self.parts.booster.stats.mechMass + self.parts.legs.stats.mechMass + self.parts.leftArm.stats.mechMass + self.parts.rightArm.stats.mechMass

		-- *********************** movement penalties for Mass *****************************************************
		if self.mechMass > 20 then	-- is the mech a heavy mech? penalties for movement are worse if so
			-- setup booster mass modifier
			self.airControlSpeed = (self.parts.booster.airControlSpeed - (self.mechMass/30)) * (self.mobilityControlValue or 1)
			self.flightControlSpeed = (self.parts.booster.flightControlSpeed - (self.mechMass/30))	* (self.mobilityBoostValue or 1)

			-- setup legs affected by mass modifier
			self.groundSpeed = ((self.parts.legs.groundSpeed - (self.mechMass/20)) * self.mobilityBoostValue) + (self.bonusWalkSpeed or 0)
			self.jumpVelocity = ((self.parts.legs.jumpVelocity - (self.mechMass/20)) * self.mobilityControlValue) * (self.mobilityJumpValue or 1)
		else
			-- setup booster mass modifier
			self.airControlSpeed = (self.parts.booster.airControlSpeed - (self.mechMass/60)) * (self.mobilityControlValue or 1)
			self.flightControlSpeed = (self.parts.booster.flightControlSpeed - (self.mechMass/60)) * (self.mobilityBoostValue or 1)

			-- setup legs affected by mass modifier
			self.groundSpeed = ((self.parts.legs.groundSpeed - (self.mechMass/40)) * self.mobilityBoostValue) + (self.bonusWalkSpeed or 0)
			self.jumpVelocity = ((self.parts.legs.jumpVelocity - (self.mechMass/40)) * self.mobilityControlValue) * (self.mobilityJumpValue or 1)
		end
end


-- fu modularmech.lua update() with NPC Mechs support (LoPhatKo)


function update(dt)

	-- despawn if owner has left the world
	if not self.ownerEntityId or world.entityType(self.ownerEntityId) ~= "player" then
		despawn()
	end

	--set storage.energy based on fuel in dummy quest
	if not self.currentFuelMessage then
		self.currentFuelMessage = world.sendEntityMessage(self.ownerEntityId, "getQuestFuelCount")
	end

	if self.currentFuelMessage and self.currentFuelMessage:finished() and storage.energy then
		if self.currentFuelMessage:succeeded() and self.currentFuelMessage:result() then
			storage.energy = self.currentFuelMessage:result()
		end
		self.currentFuelMessage = nil
	end
	--end

	if self.explodeTimer then
		self.explodeTimer = math.max(0, self.explodeTimer - dt)
		if self.explodeTimer == 0 then
			local params = {
				referenceVelocity = mcontroller.velocity(),
				damageTeam = {
					type = "enemy",
					team = 9001
				}
			}
			world.spawnProjectile(self.explodeProjectile, mcontroller.position(), nil, nil, false, params)
			animator.playSound("explode")
			vehicle.destroy()
		else
			local fade = 1 - (self.explodeTimer / self.explodeTime)
			animator.setGlobalTag("directives", string.format("?fade=FCC93C;%.1f", fade))
		end
		return
	elseif self.despawnTimer then
		self.despawnTimer = math.max(0, self.despawnTimer - dt)
		if self.despawnTimer == 0 then
			vehicle.destroy()
		else
			local multiply, fade, light
			if self.despawnTimer > 0.5 * self.despawnTime then
				fade = 1.0 - (self.despawnTimer - 0.5 * self.despawnTime) / (0.5 * self.despawnTime)
				light = fade
				multiply = 255
			else
				fade = 1.0
				light = self.despawnTimer / (0.5 * self.despawnTime)
				multiply = math.floor(255 * light)
			end
			animator.setGlobalTag("directives", string.format("?multiply=ffffff%02x?fade=ffffff;%.1f", multiply, fade))
			animator.setLightActive("deployLight", true)
			animator.setLightColor("deployLight", {light, light, light})
		end
		return
	end


	--manual flight mode
	if self.manualFlightMode then
			setFlightMode(true)
	else
		setFlightMode(world.gravity(mcontroller.position()) == 0)-- or world.liquidAt(mcontroller.position()))--lpk:add liquidMovement
	end

	if self.manualFlightMode and world.gravity(mcontroller.position()) == 0 then
		self.manualFlightMode = false
	end

	-- update positions and movement

	self.boostDirection = {0, 0}

	local newPosition = mcontroller.position()
	local newVelocity = mcontroller.velocity()

	-- decrement timers

	self.stepSoundLimitTimer = math.max(0, self.stepSoundLimitTimer - dt)
	self.landingBobTimer = math.max(0, self.landingBobTimer - dt)
	self.jumpBoostTimer = math.max(0, self.jumpBoostTimer - dt)
	self.fallThroughTimer = math.max(0, self.fallThroughTimer - dt)
	self.onGroundTimer = math.max(0, self.onGroundTimer - dt)

	-- track onGround status
	if mcontroller.onGround() then
		self.onGroundTimer = self.onGroundTime
	end
	local onGround = self.onGroundTimer > 0

	-- hit ground

	if onGround and not self.lastOnGround and newVelocity[2] - self.lastVelocity[2] > self.landingBobThreshold then
		self.landingBobTimer = self.landingBobTime
		triggerStepSound()
	end

	-- update driver if energy > 0

	local driverId = vehicle.entityLoungingIn("seat")
	if driverId and not self.driverId and storage.energy > 0 then
		animator.setAnimationState("power", "activate")
	elseif self.driverId and not driverId and storage.energy > 0 then
		animator.setAnimationState("power", "deactivate")
	end
	self.driverId = driverId


	-- NPC Mechs compatbility
	if self.driverId ~= self.ownerEntityId then
		storage.energy = self.energyMax
	end

	-- read controls or do deployment

	local newControls = {}
	local oldControls = self.lastControls
	local walking = false

	if self.deploy then
		self.deploy.fadeTimer = math.max(0.0, self.deploy.fadeTimer - dt)
		self.deploy.deployTimer = math.max(0.0, self.deploy.deployTimer - dt)

		-- visual fade in
		local multiply = math.floor(math.min(1.0, (self.deploy.fadeTime - self.deploy.fadeTimer) / self.deploy.fadeInTime) * 255)
		local fade = math.min(1.0, self.deploy.fadeTimer / self.deploy.fadeOutTime)
		animator.setGlobalTag("directives", string.format("?multiply=ffffff%02x?fade=ffffff;%.1f", multiply, fade))
		animator.setLightActive("deployLight", true)
		animator.setLightColor("deployLight", {fade, fade, fade})

		-- boost to a stop
		if self.deploy.deployTimer < self.deploy.boostTime then
			mcontroller.approachYVelocity(0, math.abs(self.deploy.initialVelocity) / self.deploy.boostTime * mcontroller.parameters().mass)
			boost({0, util.toDirection(-self.deploy.initialVelocity)})
		end

		if self.deploy.deployTimer == 0.0 then
			self.deploy = nil
			animator.setLightActive("deployLight", false)
		end
	else
		self.damageFlashTimer = math.max(0, self.damageFlashTimer - dt)
		if self.damageFlashTimer == 0 then
			animator.setGlobalTag("directives", "")
		end

		if self.driverId then
			-- for k, _ in pairs(self.lastControls) do
				-- newControls[k] = vehicle.controlHeld("seat", k)
			-- end
			-- self.aimPosition = vehicle.aimPosition("seat")
			self.aimPosition,newControls = readMechControls(newControls) -- NPC Mechs

			if newControls.Special1 and not self.lastControls.Special1 and storage.energy > 0 then
					if self.parts.hornName == 'mechaimassist' then
						self.aimassist = not self.aimassist
						animator.playSound('toggle'..(self.aimassist and 'on' or 'off'))
					elseif self.parts.hornName == 'mechmasscancel' or self.parts.hornName == 'mechmasscancel2' or self.parts.hornName == 'mechmasscancel3' or self.parts.hornName == 'mechmasscancel4' then
						self.masscancel = not self.masscancel
						animator.playSound('toggle'..(self.masscancel and 'on' or 'off'))
					else
					animator.playSound("horn")
				end
			end

			if self.flightMode then
				--disable manual flight mode on no energy
				if storage.energy <= 0 and self.manualFlightMode then
					setFlightMode(false)
					self.manualFlightMode = false
				end

				if self.manualFlightMode and mcontroller.yVelocity() > 0 and mcontroller.isColliding() then
					setFlightMode(false)
					self.manualFlightMode = false
				end

						if not hasTouched(newControls) and not hasTouched(oldControls) and self.manualFlightMode then
							local vel = mcontroller.velocity()
							if vel[1] ~= 0 or vel[2] ~= 0 then
								--mcontroller.approachVelocity({0, 0}, self.flightControlForce*2)
								mcontroller.approachVelocity({0, 0}, self.flightControlForce*1.5)
								boost(vec2.mul(vel, -1))
							end
						end

						--set controls to only working on positive energy
				if newControls.jump then
					local vel = mcontroller.velocity()
					if vel[1] ~= 0 or vel[2] ~= 0 then
						mcontroller.approachVelocity({0, 0}, self.flightControlForce)
						boost(vec2.mul(vel, -1))
					end
				else
					if newControls.right and storage.energy > 0 then
						mcontroller.approachXVelocity(self.flightControlSpeed, self.flightControlForce)
						boost({1, 0})
					end

					if newControls.left and storage.energy > 0 then
						mcontroller.approachXVelocity(-self.flightControlSpeed, self.flightControlForce)
						boost({-1, 0})
					end

					if newControls.up and storage.energy > 0 then
						mcontroller.approachYVelocity(self.flightControlSpeed, self.flightControlForce)
						boost({0, 1})
					end

					if newControls.down and storage.energy > 0 then
						if self.manualFlightMode then
							mcontroller.approachYVelocity(-self.flightControlSpeed*2, self.flightControlForce*2)
						else
							mcontroller.approachYVelocity(-self.flightControlSpeed, self.flightControlForce)
						end
						boost({0, -1})
					end
				end
			else
				if not newControls.jump and storage.energy > 0 then
					self.fallThroughSustain = false
				end

				if onGround then
					if newControls.right and not newControls.left and storage.energy > 0 then
						mcontroller.approachXVelocity(self.groundSpeed, self.groundControlForce)
						walking = true
					end

					if newControls.left and not newControls.right and storage.energy > 0 then
						mcontroller.approachXVelocity(-self.groundSpeed, self.groundControlForce)
						walking = true
					end

					if newControls.jump and self.jumpBoostTimer > 0 and storage.energy > 0 then
						mcontroller.setYVelocity(self.jumpVelocity)
					elseif newControls.jump and not self.lastControls.jump then
						if newControls.down and storage.energy > 0 then
							self.fallThroughTimer = self.fallThroughTime
							self.fallThroughSustain = true
						else
							jump()

							self.doubleTabBoostJump = self.doubleTabBoostOn
						end
					else
						self.jumpBoostTimer = 0
					end

					--crouch code is here
					local dist = self.crouchCheckMax
					self.crouchTarget = 0.0
					self.crouchOn = false

					while dist > 0 do
						if (newControls.down and not self.fallThroughSustain) or (
							world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), {-2.5, dist})) or
							world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), {0, dist})) or
							world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), {2.5, dist}))
							) then
							self.crouchOn = true
							self.crouchTarget = 1.0 - dist / self.crouchCheckMax
						else
							break
						end
						dist = dist - 1
					end
					--end

				else
					local controlSpeed = self.jumpBoostTimer > 0 and self.jumpAirControlSpeed or self.airControlSpeed
					local controlForce = self.jumpBoostTimer > 0 and self.jumpAirControlForce or self.airControlForce

					local boostSpeedMult = self.doubleTabBoostJump and self.doubleTabBoostSpeedMultTarget or 1.0

					if newControls.right and storage.energy > 0 then
						mcontroller.approachXVelocity(controlSpeed * boostSpeedMult, controlForce)
						boost({1, 0})
					end

					if newControls.left and storage.energy > 0 then
						mcontroller.approachXVelocity(-controlSpeed * boostSpeedMult, controlForce)
						boost({-1, 0})
					end

					if newControls.jump and storage.energy > 0 then
						if self.jumpBoostTimer > 0 then
							mcontroller.setYVelocity(self.jumpVelocity)
						end
					else
						self.jumpBoostTimer = 0
					end

					--crouch code is here
					self.crouchTarget = 0.0
					self.crouchOn = false
					--end
				end

				doubleTabBoost(dt, newControls, oldControls)
			end

			self.facingDirection = world.distance(self.aimPosition, mcontroller.position())[1] > 0 and 1 or -1

			self.lastControls = newControls
		else
			for k, _ in pairs(self.lastControls) do
				self.lastControls[k] = false
			end

			newControls = self.lastControls
			oldControls = self.lastControls

			self.aimPosition = nil
		end
	end

	--manual flight mode
	if not self.driverId then
		setFlightMode(false)
		self.manualFlightMode = false
	end

	if newControls.up and not oldControls.up then
		self.doubleJumpCount = self.doubleJumpCount + 1
		self.doubleJumpDelay = self.doubleTabCheckDelayTime
	end

	if self.doubleJumpCount >= 2 then
		if self.manualFlightMode == true and world.gravity(mcontroller.position()) ~= 0 then
			self.manualFlightMode = false
		elseif self.manualFlightMode == false and world.gravity(mcontroller.position()) ~= 0 then
			self.manualFlightMode = true
		end

		self.doubleJumpCount = 0
	end

	self.doubleJumpDelay = self.doubleJumpDelay - dt
	if self.doubleJumpDelay < 0 then
		self.doubleJumpCount = 0
	end
	--end

	--crouch code is here
	if storage.energy > 0 then
		--self.crouch = self.crouch + (self.crouchTarget - self.crouch) * 0.1
		self.crouch = util.lerp(0.1,self.crouch,self.crouchTarget)
	end

	if not self.flightMode then --lpk - dont set while in 0g
		self.crouchTarget = 0.5
		self.crouchOn = true
		if self.crouchOn then

			mcontroller.applyParameters(self.crouchSettings)
		else
			mcontroller.applyParameters(self.noneCrouchSettings)
		end
	end

	-- update damage team (don't take damage without a driver)
	-- also anything else that depends on a driver's presence
	if self.driverId then
		vehicle.setDamageTeam(world.entityDamageTeam(self.driverId))
		vehicle.setInteractive(false)
		vehicle.setForceRegionEnabled("itemMagnet", true)
		vehicle.setDamageSourceEnabled("bumperGround", not self.flightMode)
		animator.setLightActive("activeLight", true)
	else
		vehicle.setDamageTeam({type = "ghostly"})
		vehicle.setInteractive(true)
		vehicle.setForceRegionEnabled("itemMagnet", false)
		vehicle.setDamageSourceEnabled("bumperGround", false)
		animator.setLightActive("activeLight", false)
		animator.setLightActive("boostLight", false)
	end

	-- decay and check energy
	if self.driverId then
	--energy drain
		local energyDrain = self.energyDrain --base rate

		-- determine health/energy loss in hostile environments, based on the mass of the mech
        if self.healthDrain > 0 then --do not do this if their HP is too low
        	totalMass()
			if self.massTotal > 47 then
        		self.healthDrain = 0.05
			elseif self.massTotal > 44 then
        		self.healthDrain = 0.2
        	elseif self.massTotal > 36 then
        		self.healthDrain = 0.5
        	elseif self.massTotal > 29 then
        		self.healthDrain = 0.65
        	elseif self.massTotal > 22 then
        		self.healthDrain = 0.75
        	else
        		self.healthDrain = 1
        	end
        	storage.health = storage.health - self.healthDrain	-- drain health per tick
        	storage.energy = storage.energy - (self.healthDrain/8) -- drain energy per tick as well
        end

		--set energy drain x2 on manual flight mode
		if self.flightMode and world.gravity(mcontroller.position()) == 0 then
			energyDrain = self.energyDrain
		elseif self.flightMode and world.gravity(mcontroller.position()) ~= 0 then --flying in Gravity takes x2 fuel
			energyDrain = self.energyDrain*2
		elseif not self.flightMode and world.gravity(mcontroller.position()) ~= 0 then	--walking consumes 50% fuel (when in biomes with gravity)
			energyDrain = self.energyDrain * 0.5
		end

		--set energy drain to 0 if null movement
		if not hasTouched(newControls) and not hasTouched(oldControls) and not self.manualFlightMode then

			eMult = vec2.mag(newVelocity) < 1.2 and 1 or 0 -- mag of vel in grav while idle = 1.188~
			eMult = eMult

			activateFUMechStats()

			if self.defenseboost then
				if self.parts.hornName == 'mechdefensefield' then
					self.defenseBoost = 50
				elseif self.parts.hornName == 'mechdefensefield2' then
					self.defenseBoost = 100
				elseif self.parts.hornName == 'mechdefensefield3' then
					self.defenseBoost = 150
				elseif self.parts.hornName == 'mechdefensefield4' then
					self.defenseBoost = 200
				elseif self.parts.hornName == 'mechdefensefield5' then
					self.defenseBoost = 250
				end
			end

			if self.masspassive then
				if self.parts.hornName == 'mechchipfeather' then
					self.mechMass = self.mechMass * 0.4
					self.healthMax = self.healthMax * 0.75
				end
			end

			if self.masscancel then
				if self.parts.hornName == 'mechmasscancel' then
					self.mechMass = self.mechMass * 0.75
				elseif self.parts.hornName == 'mechmasscancel2' then
					self.mechMass = self.mechMass * 0.5
				elseif self.parts.hornName == 'mechmasscancel3' then
					self.mechMass = self.mechMass * 0.25
				elseif self.parts.hornName == 'mechmasscancel4' then
					self.mechMass = 0
				end
			end

			if self.energyboost then
				if self.parts.hornName == 'mechenergyfield' then
					self.energyBoost = 50
				elseif self.parts.hornName == 'mechenergyfield2' then
					self.energyBoost = 100
				elseif self.parts.hornName == 'mechenergyfield3' then
					self.energyBoost = 150
				elseif self.parts.hornName == 'mechenergyfield4' then
					self.energyBoost = 200
				elseif self.parts.hornName == 'mechenergyfield5' then
					self.energyBoost = 250
				end
			end

			if self.mobilityboost then
				if self.parts.hornName == 'mechmobility' then
					self.mobilityBoostValue = 1.1
					self.mobilityControlValue = 1.1
					self.mobilityJumpValue = 1
				elseif self.parts.hornName == 'mechmobility2' then
					self.mobilityBoostValue = 1.2
					self.mobilityControlValue = 1.2
					self.mobilityJumpValue = 1
				elseif self.parts.hornName == 'mechmobility3' then
					self.mobilityBoostValue = 1.3
					self.mobilityControlValue = 1.3
					self.mobilityJumpValue = 1
				elseif self.parts.hornName == 'mechmobility4' then
					self.mobilityBoostValue = 1.4
					self.mobilityControlValue = 1.4
					self.mobilityJumpValue = 1
				elseif self.parts.hornName == 'mechmobility5' then
					self.mobilityBoostValue = 1.5
					self.mobilityControlValue = 1.5
					self.mobilityJumpValue = 1
				elseif self.parts.hornName == 'mechchipcontrol' then
					self.mobilityBoostValue = 0.8
					self.mobilityControlValue = 1.4
					self.mobilityJumpValue = 1.2
				elseif self.parts.hornName == 'mechchipspeed' then
					self.mobilityBoostValue = 1.2
					self.mobilityControlValue = 0.8
					self.mobilityJumpValue = 0.8
				end
			else
				self.mobilityBoostValue = 1
				self.mobilityControlValue = 1
				self.mobilityJumpValue = 1
			end


			if self.fuelboost then
				if self.parts.hornName == 'mechchipfuel' then
					self.healthMax = self.healthMax * 0.8
					self.energyBoost = 300
				elseif self.parts.hornName == 'mechchiprefueler' then
					self.fuelCost = 0.6
				elseif self.parts.hornName == 'mechchipovercharge' then
					self.fuelCost = 2.5
					self.mobilityBoostValue = 1.8
				end
			else
				self.fuelCost = 1
			end

			if (storage.health) < (self.healthMax*0.15) then -- play damage effects at certain health percentages
				animator.setParticleEmitterActive("highDamage", true) -- land fx
				animator.setParticleEmitterActive("midDamage", false) -- land fx
				animator.setParticleEmitterActive("lowDamage", false) -- land fx
				animator.setParticleEmitterActive("minorDamage", false) -- land fx
			elseif (storage.health) < (self.healthMax*0.25) then
				animator.setParticleEmitterActive("highDamage", false) -- land fx
				animator.setParticleEmitterActive("midDamage", true) -- land fx
				animator.setParticleEmitterActive("lowDamage", false) -- land fx
				animator.setParticleEmitterActive("minorDamage", false) -- land fx
			elseif (storage.health) < (self.healthMax*0.40) then
				animator.setParticleEmitterActive("midDamage", false) -- land fx
				animator.setParticleEmitterActive("highDamage", false) -- land fx
				animator.setParticleEmitterActive("lowDamage", true) -- land fx
				animator.setParticleEmitterActive("minorDamage", false) -- land fx
			elseif (storage.health) < (self.healthMax*0.60) then
				animator.setParticleEmitterActive("lowDamage", false) -- land fx
				animator.setParticleEmitterActive("midDamage", false) -- land fx
				animator.setParticleEmitterActive("highDamage", false) -- land fx
				animator.setParticleEmitterActive("minorDamage", true) -- land fx
			else
				animator.setParticleEmitterActive("lowDamage", false) -- land fx
				animator.setParticleEmitterActive("midDamage", false) -- land fx
				animator.setParticleEmitterActive("highDamage", false) -- land fx
				animator.setParticleEmitterActive("minorDamage", false) -- land fx
			end

			energyDrain = 0
		end

		storage.energy = math.max(0, storage.energy - energyDrain * dt)
	end

	local inLiquid = world.liquidAt(mcontroller.position())
	if inLiquid then
		local liquidName = root.liquidName(inLiquid[1])
		if self.liquidVulnerabilities[liquidName] then
			-- check to see if we're actually vulnerable
			local liquidImmunities = self.parts.body.liquidImmunities or {}
			if not liquidImmunities[liquidName] then
				-- apply energy drain / fill
				local energyBuffer=(self.liquidVulnerabilities[liquidName].energyDrain or 0) * dt
				if (energyBuffer>=0) or (storage.energy < self.energyMax) then
					storage.energy = math.max(0, storage.energy - energyBuffer)
				end

				-- apply health drain
				storage.health = math.max(0, storage.health - ((self.liquidVulnerabilities[liquidName].healthDrain or 0) * dt))

				-- only warn once, only warn when not immune
				if not self.liquidVulnerabilities[liquidName].warned then
					world.sendEntityMessage(self.ownerEntityId, "queueRadioMessage", self.liquidVulnerabilities[liquidName].message)
					self.liquidVulnerabilities[liquidName].warned = true
				end
			end
		end
	end

	-- this has to happen after the last time we edit storage.energy
	if self.driverId and world.entityType(self.driverId) == "player" then
		--set new fuel count on dummy quest
		world.sendEntityMessage(self.ownerEntityId, "setQuestFuelCount", storage.energy)
	end

	--explode on 0 health
	if storage.health == 0 then
		explode()
		return
	end

	--lock arms and set sounds on 0 energy
	if storage.energy <= 0 then
		self.energyBackPlayed = false
		self.leftArm.bobLocked = true
		self.rightArm.bobLocked = true
		animator.setAnimationState("boost", "idle")
		animator.setLightActive("boostLight", false)
		animator.stopAllSounds("step")
		animator.stopAllSounds("jump")
		if not self.energyOutPlayed then
			animator.setAnimationState("power", "deactivate")
			animator.playSound("energyout")
			self.energyOutPlayed = true
		end

		for _, arm in pairs({"left", "right"}) do
			animator.resetTransformationGroup(arm .. "Arm")
			animator.resetTransformationGroup(arm .. "ArmFlipper")

			self[arm .. "Arm"]:updateBase(dt, self.driverId, false, false, self.aimPosition, self.facingDirection, self.crouch * self.bodyCrouchMax)
			self[arm .. "Arm"]:update(dt)
		end
		return
	else
		self.energyOutPlayed = false
		self.leftArm.bobLocked = false
		self.rightArm.bobLocked = false
		if not self.energyBackPlayed then
			animator.setAnimationState("power", "activate")
			animator.playSound("energyback")
			self.energyBackPlayed = true
		end
	end

	-- set appropriate movement parameters for walking/falling conditions

	if not self.flightMode then
		if walking ~= self.lastWalking then
			self.lastWalking = walking
			if self.lastWalking then
				mcontroller.applyParameters(self.walkingMovementSettings)
			else
				mcontroller.resetParameters(self.movementSettings)
			end
		end

		if self.fallThroughTimer > 0 or self.fallThroughSustain then
			mcontroller.applyParameters({ignorePlatformCollision = true})
		else
			mcontroller.applyParameters({ignorePlatformCollision = false})
		end
	end

	-- flip to match facing direction

	if storage.energy > 0 then
		animator.setFlipped(self.facingDirection < 0)
	end

	-- compute leg cycle

	if onGround then
		local newLegCycle = self.legCycle + ((newPosition[1] - self.lastPosition[1]) * self.facingDirection) / (4 * self.legRadius)

		if math.floor(self.legCycle * 2) ~= math.floor(newLegCycle * 2) then
			triggerStepSound()
			-- mech ground thump damage (FU)
			self.thumpParamsMini = {power = self.mechMass,damageTeam = {type = "friendly"},actionOnReap = {{action='explosion',foregroundRadius=2,backgroundRadius=0,explosiveDamageAmount= 0.25,harvestLevel = 99,delaySteps=2}}}

			if self.mechMass > 8 then	-- 8 tonne minimum or tiles dont suffer at all.
				world.spawnProjectile("mechThump", mcontroller.position(), nil, {0,-6}, false, self.thumpParamsMini)
			end
			animator.burstParticleEmitter("legImpactLight")--little puffs of smoke for juicyness
		end

		self.legCycle = newLegCycle
	end

	-- animate legs, leg joints, and hips
	if self.flightMode then
		-- legs stay locked in place for flight
	else
		local legs = {
			front = {},
			back = {}
		}
		local legCycleOffset = 0

		for _, legSide in pairs({"front", "back"}) do
			local leg = legs[legSide]

			leg.offset = legOffset(self.legCycle + legCycleOffset)
			legCycleOffset = legCycleOffset + 0.5

			leg.onGround = leg.offset[2] <= 0

			-- put foot down when stopped
			if not walking and math.abs(newVelocity[1]) < 0.5 then
				leg.offset[2] = 0
				leg.onGround = true
			end

			local footGroundOffset = findFootGroundOffset(leg.offset, self[legSide .. "Foot"])
			if footGroundOffset then
				leg.offset[2] = leg.offset[2] + footGroundOffset
			else
				leg.offset[2] = self.reachGroundDistance[2]
				leg.onGround = false
			end

			animator.setAnimationState(legSide .. "Foot", leg.onGround and "flat" or "tilt")
			animator.resetTransformationGroup(legSide .. "Leg")
			animator.translateTransformationGroup(legSide .. "Leg", leg.offset)
			animator.resetTransformationGroup(legSide .. "LegJoint")
			animator.translateTransformationGroup(legSide .. "LegJoint", {0.6 * leg.offset[1], 0.5 * leg.offset[2]})
		end

		if math.abs(newVelocity[1]) < 0.5 and math.abs(self.lastVelocity[1]) >= 0.5 then
			triggerStepSound()
		end

		animator.resetTransformationGroup("hips")
		local hipsOffset = math.max(-0.375, math.min(0, legs.front.offset[2] + 0.25, legs.back.offset[2] + 0.25)) + (self.crouch * self.hipCrouchMax)
		animator.translateTransformationGroup("hips", {0, hipsOffset})
	end

	-- update and animate arms

	local chains = {}
	for _, arm in pairs({"left", "right"}) do
		local fireControl = (arm == "left") and "PrimaryFire" or "AltFire"

		local aim = self.aimPosition
		if self.aimassist and self.aimPosition and self[arm..'Arm'].projectileType then
			local projectile = root.projectileConfig(self[arm..'Arm'].projectileType)
			if projectile.speed and projectile.speed > 0 then
				local armVec = world.xwrap(vec2.add(vec2.add(mcontroller.position(),{0, self.walkBobMagnitude * math.sin(math.pi * (((self.legCycle * 2) - self.armBobDelay) % 1)) + (self.crouch * self.bodyCrouchMax)}),arm == 'left' and {2.375,1.798} or {-2.375,1.798}))
				local mechVec = mcontroller.velocity()
				local aimAngle = vec2.angle(world.distance(self.aimPosition,armVec))
				local mechVel = mechVec[1]*-1*math.sin(aimAngle)+mechVec[2]*math.cos(aimAngle)
				local dist = world.magnitude(armVec,self.aimPosition)-self[arm..'Arm'].fireOffset[1]
				local aimOffset = (mechVel ~= 0 and math.atan(mechVel*(dist/projectile.speed),dist) or 0)
				aim = world.xwrap(vec2.add(armVec,{math.cos(aimAngle-aimOffset),math.sin(aimAngle-aimOffset)}))
			end
		end

		animator.resetTransformationGroup(arm .. "Arm")
		animator.resetTransformationGroup(arm .. "ArmFlipper")

		self[arm .. "Arm"]:updateBase(dt, self.driverId, newControls[fireControl], oldControls[fireControl], aim, self.facingDirection, self.crouch * self.bodyCrouchMax, self.parts) --FU adds self.parts

		self[arm .. "Arm"]:update(dt)
		if self[arm.."Arm"].renderChain then
			table.insert(chains, self[arm.."Arm"].chain)
		end

		if self.facingDirection < 0 then
			animator.translateTransformationGroup(arm .. "ArmFlipper", {(arm == "right") and self.armFlipOffset or -self.armFlipOffset, 0})
		end
	end
	vehicle.setAnimationParameter("chains", chains)

	-- animate boosters and boost flames

	animator.resetTransformationGroup("boosters")

	if self.jumpBoostTimer > 0 then
		boost({0, 1})
	end

	if self.manualFlightMode then
		boost({0, 1})
	end

	if storage.energy <= 0 then
		animator.setAnimationState("boost", "idle")
		animator.setLightActive("boostLight", false)
	end

	if self.boostDirection[1] == 0 and self.boostDirection[2] == 0 then
		animator.setAnimationState("boost", "idle")
		animator.setLightActive("boostLight", false)
	else
		local stateTag = "boost"
		if self.boostDirection[2] > 0 then
			stateTag = stateTag .. "N"
		elseif self.boostDirection[2] < 0 then
			stateTag = stateTag .. "S"
		end
		if self.boostDirection[1] * self.facingDirection > 0 then
			stateTag = stateTag .. "E"
		elseif self.boostDirection[1] * self.facingDirection < 0 then
			stateTag = stateTag .. "W"
		end
		animator.setAnimationState("boost", stateTag)
		animator.setLightActive("boostLight", true)
	end

	-- animate bobbing and landing
	-- FU timer ***********************************
	time = (time or 1) - dt

	animator.resetTransformationGroup("body")
	if self.flightMode then
		local newFlightOffset = {
			math.max(-self.flightOffsetClamp, math.min(self.boostDirection[1] * self.facingDirection * self.flightOffsetFactor, self.flightOffsetClamp)),
			math.max(-self.flightOffsetClamp, math.min(self.boostDirection[2] * self.flightOffsetFactor, self.flightOffsetClamp))
		}

		self.currentFlightOffset = vec2.div(vec2.add(newFlightOffset, vec2.mul(self.currentFlightOffset, 4)), 5)

		animator.translateTransformationGroup("boosters", self.currentFlightOffset)
		animator.translateTransformationGroup("rightArm", self.currentFlightOffset)
		animator.translateTransformationGroup("leftArm", self.currentFlightOffset)
	elseif not onGround or self.jumpBoostTimer > 0 then
		-- TODO: bob while jumping?
	elseif self.landingBobTimer == 0 then
		local bodyCycle = (self.legCycle * 2) % 1
		local bodyOffset = {0, self.walkBobMagnitude * math.sin(math.pi * bodyCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("body", bodyOffset)

		local boosterCycle = ((self.legCycle * 2) - self.boosterBobDelay) % 1
		local boosterOffset = {0, self.walkBobMagnitude * math.sin(math.pi * boosterCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("boosters", boosterOffset)

		local armCycle = ((self.legCycle * 2) - self.armBobDelay) % 1
		local armOffset = {0, self.walkBobMagnitude * math.sin(math.pi * armCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("rightArm", self.rightArm.bobLocked and boosterOffset or armOffset)
		animator.translateTransformationGroup("leftArm", self.leftArm.bobLocked and boosterOffset or armOffset)
	else
		-- TODO: make this less complicated
		local landingCycleTotal = 1.0 + math.max(self.boosterBobDelay, self.armBobDelay)
		local landingCycle = landingCycleTotal * (1 - (self.landingBobTimer / self.landingBobTime))

		local bodyCycle = math.max(0, math.min(1.0, landingCycle))
		local bodyOffset = {0, -self.landingBobMagnitude * math.sin(math.pi * bodyCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("body", bodyOffset)

		local legJointOffset = {0, 0.5 * bodyOffset[2]}
		animator.translateTransformationGroup("frontLegJoint", legJointOffset)
		animator.translateTransformationGroup("backLegJoint", legJointOffset)

		local boosterCycle = math.max(0, math.min(1.0, landingCycle + self.boosterBobDelay))
		local boosterOffset = {0, -self.landingBobMagnitude * 0.5 * math.sin(math.pi * boosterCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("boosters", boosterOffset)

		local armCycle = math.max(0, math.min(1.0, landingCycle + self.armBobDelay))
		local armOffset = {0, -self.landingBobMagnitude * 0.25 * math.sin(math.pi * armCycle) + (self.crouch * self.bodyCrouchMax)}
		animator.translateTransformationGroup("rightArm", self.rightArm.bobLocked and boosterOffset or armOffset)
		animator.translateTransformationGroup("leftArm", self.leftArm.bobLocked and boosterOffset or armOffset)

		-- ************************************ MECH MASS IMPACT (FU) ************************************
		if vehicle.entityLoungingIn("seat") then	-- only check mech mass application on terrain if the player is within the mech, to prevent weird cratering issues


			self.explosivedamage = math.min(math.abs(mcontroller.velocity()[2]) * self.mechMass,55)
			self.baseDamage = math.min(math.abs(mcontroller.velocity()[2]) * self.mechMass,300)
			self.appliedDamage = self.baseDamage /2

			-- if it falls too hard, the mech takes some damage based on how far its gone
			self.baseDamageMechfall = math.min(math.abs(mcontroller.velocity()[2]) * self.mechMass)/2

			if self.mechMass >= 15 and (self.baseDamageMechfall) >= 220 and (self.jumpBoostTimer) == 0 then		--mech takes damage from stomps
				storage.health = math.max(0, storage.health - (self.baseDamage /100))
			end

			if self.mechMass > 0 and time <= 0 then
				time = 1
				local thumpParamsBig = {
				power = self.appliedDamage,
				damageTeam = {type = "friendly"},
				actionOnReap = {{action='explosion',foregroundRadius=math.abs(mcontroller.velocity()[2]),backgroundRadius=0,explosiveDamageAmount= self.explosivedamage,harvestLevel = 99,delaySteps=2}}}

				if self.mechMass >= 20 then
					thumpParamsBig.actionOnReap[1].foregroundRadius = thumpParamsBig.actionOnReap[1].foregroundRadius / (6 - (self.mechMass/24))
					thumpParamsBig.actionOnReap[1].backgroundRadius = thumpParamsBig.actionOnReap[1].backgroundRadius / 6
					thumpParamsBig.actionOnReap[1].explosiveDamageAmount = thumpParamsBig.actionOnReap[1].explosiveDamageAmount * 1.5
				elseif self.mechMass >= 11 then
					thumpParamsBig.actionOnReap[1].foregroundRadius = thumpParamsBig.actionOnReap[1].foregroundRadius / 7.4
				else
					thumpParamsBig.actionOnReap[1].foregroundRadius = thumpParamsBig.actionOnReap[1].foregroundRadius / 10
				end

				world.spawnProjectile("mechThumpLarge", mcontroller.position(), nil, {3,-6}, false, thumpParamsBig)
				world.spawnProjectile("mechThumpLarge", mcontroller.position(), nil, {-3,-6}, false, thumpParamsBig)
			end

			-- separate so that it always applies regardless of actual damage, because it looks cool
			if self.mechMass >= 20 and (self.explosivedamage) >= 40 then
				animator.playSound("landingThud")
				animator.playSound("heavyBoom")
				animator.burstParticleEmitter("legImpactHeavy")
			else
				animator.playSound("landingThud")
				animator.burstParticleEmitter("legImpact")
			end

		end
	end
	--

	self.lastPosition = newPosition
	self.lastVelocity = newVelocity
	self.lastOnGround = onGround
end

function readMechControls(newControls)
	for k, _ in pairs(self.lastControls) do
		newControls[k] = vehicle.controlHeld("seat", k)
	end

	return vehicle.aimPosition("seat"),newControls
end

function onInteraction(args)
	local playerUuid = world.entityUniqueId(args.sourceId)
	if not self.driverId and playerUuid ~= self.ownerUuid then
		return "None"
	end
end

function applyDamage(damageRequest)
	-- if mech is higher than rank 4 in protection (body), they have a 10% chance to reduce incoming damage below a threshold
	-- otherwise, they take normal damage, reduced by the protection afforded by their mech body
    local energyLost = math.min(storage.health, damageRequest.damage * (1-self.protection))
    self.massProtection = (self.parts.body.stats.protection * (self.parts.body.stats.mechMass)/10)
    self.rand = math.random(1)
    if (self.parts.body.stats.protection >=4) and (energyLost <= self.massProtection) and (self.rand == 1) then
    	self.massProtection = self.massProtection / 10 -- divide actual protection by 10
        energyLost = energyLost * self.massProtection  -- final resisted damageg
        animator.playSound("landingThud")
        animator.burstParticleEmitter("blockDamage")
    end

    storage.health = storage.health - energyLost

    if storage.health == 0 then
        explode()
    else
        self.damageFlashTimer = self.damageFlashTime
        animator.setGlobalTag("directives", self.damageFlashDirectives)
    end

    return {{
        sourceEntityId = damageRequest.sourceEntityId,
        targetEntityId = entity.id(),
        position = mcontroller.position(),
        damageDealt = energyLost,
        healthLost = energyLost,
        hitType = damageRequest.hitType,
        damageSourceKind = damageRequest.damageSourceKind,
        targetMaterialKind = self.materialKind,
        killed = storage.health == 0
    }}
end
function jump()
	self.jumpBoostTimer = self.jumpBoostTime

	--jump only if energy > 0
	if storage.energy <= 0 then
		return
	end

	mcontroller.setYVelocity(self.jumpVelocity)
	animator.playSound("jump")
end

function armRotation(armSide)
	-- Unused. Vanilla was calculating "local rotation" variable here, but never used it afterwards.
end

function legOffset(legCycle)
	legCycle = legCycle % 1
	if legCycle < 0.5 then
		return {util.lerp(legCycle * 2, self.legRadius - 0.1, -self.legRadius - 0.1), 0}
	else
		local angle = (legCycle - 0.5) * 2 * math.pi
		local offset = vec2.withAngle(math.pi - angle, self.legRadius)
		offset[2] = offset[2] * self.legVerticalRatio
		return offset
	end
end

function findFootGroundOffset(legOffset, footOffset)
	local footBaseOffset = {self.facingDirection * (legOffset[1] + footOffset[1]), footOffset[2]}
	local footPos = vec2.add(mcontroller.position(), footBaseOffset)

	local bestGroundPos
	for _, offset in pairs(self.footCheckXOffsets) do
		world.debugPoint(vec2.add(footPos, {offset, 0}), "yellow")
		local groundPos = world.lineCollision(vec2.add(footPos, {offset, self.reachGroundDistance[1]}), vec2.add(footPos, {offset, self.reachGroundDistance[2]}), {"Null", "Block", "Dynamic", "Platform", "Slippery"})
		if groundPos and bestGroundPos then
			bestGroundPos = bestGroundPos[2] > groundPos[2] and bestGroundPos or groundPos
		elseif groundPos then
			bestGroundPos = groundPos
		end
	end
	if bestGroundPos then
		return world.distance(bestGroundPos, footPos)[2]
	end
end

function triggerStepSound()
	if self.stepSoundLimitTimer == 0 then
		animator.playSound("step")
		self.stepSoundLimitTimer = self.stepSoundLimitTime
	end
end

function resetAllTransformationGroups()
	for _, groupName in ipairs({"frontLeg", "backLeg", "frontLegJoint", "backLegJoint", "hips", "body", "rightArm", "leftArm", "boosters"}) do
		animator.resetTransformationGroup(groupName)
	end
end

function setFlightMode(enabled)
	if self.flightMode ~= enabled then
		self.flightMode = enabled
		resetAllTransformationGroups()
		self.jumpBoostTimer = 0
		self.currentFlightOffset = {0, 0}
		self.fallThroughSustain = false

		mcontroller.resetParameters(self.movementSettings)

	local vel = mcontroller.velocity()
		if vel[1] ~= 0 or vel[2] ~= 0 then
			mcontroller.approachVelocity({0, 0}, self.flightControlForce)
			boost(vec2.mul(vel, -1))
		end
		if enabled then
			mcontroller.setVelocity({0, 0})
			mcontroller.applyParameters(self.flyingMovementSettings)
			animator.setAnimationState("frontFoot", "tilt")
			animator.setAnimationState("backFoot", "tilt")
			animator.translateTransformationGroup("frontLeg", self.flightLegOffset)
			animator.translateTransformationGroup("backLeg", self.flightLegOffset)
			animator.translateTransformationGroup("frontLegJoint", vec2.mul(self.flightLegOffset, 0.5))
			animator.translateTransformationGroup("backLegJoint", vec2.mul(self.flightLegOffset, 0.5))
		else

		end
	end
end

function boost(newBoostDirection)
	self.boostDirection = vec2.add(self.boostDirection, newBoostDirection)
end

function alive()
	return not self.explodeTimer and not self.despawnTimer
end

function explode()
	if alive() then
		self.explodeTimer = self.explodeTime
		vehicle.setLoungeEnabled("seat", false)
		vehicle.setInteractive(false)
		animator.setParticleEmitterActive("explode", true)
		animator.playSound("explodeWindup")
	end
end

function despawn()
	if alive() then
		self.despawnTimer = self.despawnTime
		vehicle.setLoungeEnabled("seat", false)
		vehicle.setInteractive(false)
		animator.burstParticleEmitter("despawn")
		animator.setParticleEmitterActive("despawn", true)
		animator.playSound("despawn")
	end
end


function doubleTabBoost(dt, newControls, oldControls)
	if self.doubleTabBoostOn and storage.energy > 0 then

		-- FU CHANGES ****************************
		--mech mass affects sprint speed for mech
		self.doubleTabBoostSpeedMult = math.max(self.doubleTabBoostSpeedMultTarget - (self.mechMass/15),1.0)
		-- ***************************************

		self.crouch = self.doubleTabBoostCrouchTargetTo
		self.facingDirection = self.doubleTabBoostDirection == "right" and 1 or -1
		mcontroller.approachXVelocity(self.groundSpeed * self.doubleTabBoostSpeedMult * self.facingDirection, self.groundControlForce)
		mcontroller.setYVelocity(math.min(mcontroller.yVelocity(), -10))
		self.crouchOn = false

		if (not newControls.right and self.doubleTabBoostDirection == "right") or
			(not newControls.left and self.doubleTabBoostDirection == "left") or
			newControls.jump then
			self.doubleTabBoostOn = false
		end

	elseif self.lastOnGround and not self.crouchOn then

		self.doubleTabBoostSpeedMult = 1.0

		if newControls.right and not oldControls.right then
			self.doubleTabCount = math.max(self.doubleTabCount, 0)
			self.doubleTabCount = self.doubleTabCount + 1
			self.doubleTabCheckDelay = self.doubleTabCheckDelayTime
		end
		if newControls.left and not oldControls.left then
			self.doubleTabCount = math.min(self.doubleTabCount, 0)
			self.doubleTabCount = self.doubleTabCount - 1
			self.doubleTabCheckDelay = self.doubleTabCheckDelayTime
		end

		if self.doubleTabCount >= 2 or self.doubleTabCount <= -2 then
			self.doubleTabBoostOn = true

			if self.doubleTabCount >= 2 then
				self.doubleTabBoostDirection = "right"
			else
				self.doubleTabBoostDirection = "left"
			end

			self.doubleTabCount = 0
		end

	end

	self.doubleTabCheckDelay = self.doubleTabCheckDelay - dt
	if self.doubleTabCheckDelay < 0 then
		self.doubleTabCount = 0
	end
end

--check if controls are being touched
function hasTouched(controls)
	for _,control in pairs(controls) do
		if control then return true end
	end
	return false
end
