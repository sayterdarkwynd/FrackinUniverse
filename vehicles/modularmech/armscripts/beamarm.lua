require "/vehicles/modularmech/armscripts/base.lua"

BeamArm = MechArm:extend()

function BeamArm:init()
	self.state = FSM:new()

	if self.chain ~= nil then
		self.chain.sourcePart = self.armName
		self.chain.endPart = self.armName
	end
	self.renderChain = false
end

function BeamArm:update(dt)
	if self.state.state then
		self.state:update()
	end

	if not self.state.state then
		if self.isFiring then
			self.state:set(self.windupState, self)
		end
	end

	if self.state.state then
		self.bobLocked = true
	else
		animator.setAnimationState(self.armName, "idle")
		self.bobLocked = false
	end
end

function BeamArm:windupState()
	local stateTimer = self.windupTime

	animator.setAnimationState(self.armName, "windup")
	animator.playSound(self.armName .. "Windup")

	while stateTimer > 0 do
		animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

		local dt = script.updateDt()
		stateTimer = stateTimer - dt
		coroutine.yield()
	end

	if self.isFiring then
		self.state:set(self.fireState, self)
	else
		self.state:set(self.winddownState, self)
		animator.playSound(self.armName .. "WinddownNoFire")
	end
end


function BeamArm:statSet()
	self.mechBonusWeapon = self.stats.power + self.stats.energy
	self.mechBonusBody = self.parts.body.stats.protection + self.parts.body.stats.energy
	self.mechBonusBooster = self.parts.booster.stats.control + self.parts.booster.stats.speed
	self.mechBonusLegs = self.parts.legs.stats.speed + self.parts.legs.stats.jump
	self.mechBonusTotal = self.mechBonusLegs + self.mechBonusBooster + self.mechBonusBody -- all three combined
	self.mechBonus = ((self.mechBonusBody	/2.4) + (self.mechBonusBooster/ 3) + (self.mechBonusLegs / 2.7))
	self.energyMax = self.parts.body.energyMax
	self.weaponDrain = ((self.parts.leftArm.energyDrain or 0) + (self.parts.rightArm.energyDrain or 0))/20
	self.weaponDrainCrit = ((self.parts.leftArm.energyDrain or 0) + (self.parts.rightArm.energyDrain or 0))/10
	storage.energy = math.min(math.max(0, storage.energy - self.weaponDrain),self.energyMax)
end


function BeamArm:fireState()
	local stateTimer = self.fireTime
	-- FU beam damage scaling *******************************************
	self:statSet()
	self.mechTier = self.stats.power
	self.basePower = self.stats.basePower or 1
	self.critChance = (self.parts.body.stats.energy/2) + math.random(100)

	self.largeLaser = self.stats.largeLaser or 0	-- non-mining lasers use this stat. Default is 10.
	if self.largeLaser > 0 then
		self.basePower = 10 -- make sure our base power is easily computed
		self.applyBeamDamage = self.basePower * (1 + self.mechTier/10) * self.largeLaser
	else
		self.applyBeamDamage = self.basePower * (1 + self.mechTier/10)
	end

	pParams = config.getParameter("")	-- change this later to only read the relevant data, rather than all of it

	--Mech critical hits
	if (self.stats.rapidFire) then
		self.critMod = self.stats.rapidFire / 10
		self.critChance = self.critChance * self.critMod
	end
	if (self.critChance) >= 100 then
		self.mechBonus = self.mechBonus * 2
	end

	--apply final damage
	if (self.mechBonus) >= (self.mechBonusWeapon) then
		self.randbonus = (self.mechBonus/100) * self.mechTier
		self.mechBonus = self.mechBonus * (1 + self.randbonus)
	end

	self.applyBeamDamage = self.applyBeamDamage + self.mechBonus
	-- ********************************************************************

	animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

	local endPoint, beamCollision, beamLength = self:updateBeam()

	animator.playSound(self.armName .. "Fire")
	animator.setParticleEmitterBurstCount(self.armName .. "Beam", math.ceil(self.beamParticleDensity * beamLength))
	animator.burstParticleEmitter(self.armName .. "Beam")
	if self.scriptedBeam then
		self.renderChain = true
	else
		animator.setAnimationState(self.armName .. "Beam", "fire", true)
	end

	vehicle.setDamageSourceEnabled(self.armName .. "Beam", true)

	self.aimLocked = self.lockAim

	if beamCollision and self.beamTileDamage > 0 then
		self.maximumEndPoint = vec2.add(self.firePosition, vec2.mul(self.aimVector, self.beamLength))
		--sb.logInfo("%s %s", self.firePosition, self.maximumEndPoint)
		local damagePositions = world.collisionBlocksAlongLine(self.firePosition, self.maximumEndPoint, nil, self.beamTileDamageDepth)
		world.damageTiles(damagePositions, "foreground", self.firePosition, "beamish", self.beamTileDamage, 99)
		world.damageTiles(damagePositions, "background", self.firePosition, "beamish", self.beamTileDamage, 99)
	end
	beamParams = {}

	beamParams.timeToLive =	1
	if self.basePower == 0.05 then
		beamParams.timeToLive =	0.1
	elseif self.basePower == 0.15 then
		beamParams.timeToLive =	0.1
	elseif (self.basePower) == 1.5 then
		beamParams.timeToLive =	0.22
	elseif (self.basePower) == 2.5 then
		beamParams.timeToLive =	0.22
	elseif (self.basePower) == 3 then
		beamParams.timeToLive =	0.475
	elseif (self.basePower) == 33 then
		beamParams.timeToLive =	0.475
	elseif (self.basePower) > 33 then
		beamParams.timeToLive =	1
	end

	beamParams.speed =	120
	beamParams.power =	self.applyBeamDamage

	--set damage kind properly.
	local gleap=pParams.damageSources and pParams.damageSources[self.armName.."Beam"]
	gleap=gleap and gleap.damageSourceKind
	beamParams.damageKind=gleap
	--FU Projectile spawn, to do scaled damage *******************************************************************************
	world.spawnProjectile("fu_genericBlankProjectile", self.firePosition, self.driverId, self.aimVector , false, beamParams)
	-- ***********************************************************************************************************************

	coroutine.yield()

	while stateTimer > 0 and (self.holdFire or self.isFiring) do
		animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

		self:updateBeam()

		local dt = script.updateDt()
		stateTimer = stateTimer - dt
		coroutine.yield()
	end

	self.aimLocked = false

	if self.scriptedBeam then
		self.renderChain = false
	end

	vehicle.setDamageSourceEnabled(self.armName .. "Beam", false)

	if self.isFiring and self.repeatFire then
		self.state:set(self.fireState, self)
	else
		self.state:set(self.winddownState, self)
	end
end

function BeamArm:winddownState()
	local stateTimer = self.winddownTime or 0

	animator.setAnimationState(self.armName, "winddown")
	animator.playSound(self.armName .. "Winddown")

	if self.scriptedBeam then
		vehicle.setAnimationParameter("chains", {})
	end

	while stateTimer > 0 do
		animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

		local dt = script.updateDt()
		stateTimer = stateTimer - dt
		coroutine.yield()
	end

	self.state:set()
end

function BeamArm:updateBeam()
	local endPoint = vec2.add(self.firePosition, vec2.mul(self.aimVector, self.beamLength))
	local beamCollision = world.lineCollision(self.firePosition, endPoint)
	if beamCollision then
		endPoint = beamCollision
	end
	local beamLength = world.magnitude(self.firePosition, endPoint)

	if not self.scriptedBeam then
		animator.resetTransformationGroup(self.armName .. "Beam")
		animator.scaleTransformationGroup(self.armName .. "Beam", {beamLength, 1}, {self.beamSourceOffset[1], self.beamSourceOffset[2] - self.beamHeight / 2})
	end

	local particleRegion = {self.beamSourceOffset[1], self.beamSourceOffset[2], self.beamSourceOffset[1] + beamLength, self.beamSourceOffset[2]}
	animator.setParticleEmitterOffsetRegion(self.armName .. "Beam", particleRegion)

	return endPoint, beamCollision, beamLength
end
