require "/vehicles/modularmech/armscripts/base.lua"

BeamArm = MechArm:extend()

function BeamArm:init()
  self.state = FSM:new()
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

	-- for FU scaling damage ********************************************************
	--  self:statSet()  
	--  self.mechTier = self.stats.power
	--  pParams = config.getParameter("")  -- change this later to only read the relevant data, rather than all of it
	--  self.critChance = (self.parts.body.stats.energy/2) + math.random(100)
	  
	--  pParams.damageSources.rightArmBeam.damage = pParams.damageSources.rightArmBeam.damage * self.mechTier
	--  pParams.damageSources.leftArmBeam.damage = pParams.damageSources.leftArmBeam.damage * self.mechTier
        -- Mech critical hits
        --if self.critChance >= 100 then
        --  self.mechBonus = self.mechBonus * 2
        --end
        
          --apply final damage
          --pParams.damageSources.rightArmBeam.damage = pParams.damageSources.rightArmBeam.damage + self.mechBonus
          --pParams.damageSources.leftArmBeam.damage = pParams.damageSources.leftArmBeam.damage + self.mechBonus
          
          --sb.logInfo("power total = "..pParams.damageSources.rightArmBeam.damage)	  
	  
	  --********************************************************************************** 
	  
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
  end
end


function BeamArm:statSet()
        self.mechBonusBody = self.parts.body.stats.protection + self.parts.body.stats.energy
        self.mechBonusBooster = self.parts.booster.stats.control + self.parts.booster.stats.speed 
        self.mechBonusLegs = self.parts.legs.stats.speed + self.parts.legs.stats.jump 
        self.mechBonusTotal = self.mechBonusLegs + self.mechBonusBooster + self.mechBonusBody -- all three combined
        self.mechBonus = ((self.mechBonusBody  /2.4) + (self.mechBonusBooster/ 3) + (self.mechBonusLegs / 2.7))
        self.energyMax = self.parts.body.energyMax
        self.weaponDrain = (self.parts.leftArm.energyDrain or 0) + (self.parts.rightArm.energyDrain or 0)
        storage.energy = math.min(math.max(0, storage.energy - self.weaponDrain),self.energyMax)
        --sb.logInfo("total mech part bonus = "..self.mechBonus)
end



function BeamArm:fireState()
  local stateTimer = self.fireTime
	  
  animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

  local endPoint, beamCollision, beamLength = self:updateBeam()

  animator.playSound(self.armName .. "Fire")
  animator.setParticleEmitterBurstCount(self.armName .. "Beam", math.ceil(self.beamParticleDensity * beamLength))
  animator.burstParticleEmitter(self.armName .. "Beam")
  animator.setAnimationState(self.armName .. "Beam", "fire", true)

  vehicle.setDamageSourceEnabled(self.armName .. "Beam", true)

  self.aimLocked = self.lockAim

  if beamCollision and self.beamTileDamage > 0 then
    local maximumEndPoint = vec2.add(self.firePosition, vec2.mul(self.aimVector, self.beamLength))
    local damagePositions = world.collisionBlocksAlongLine(self.firePosition, maximumEndPoint, nil, self.beamTileDamageDepth)
    world.damageTiles(damagePositions, "foreground", self.firePosition, "beamish", self.beamTileDamage, 99)
    world.damageTiles(damagePositions, "background", self.firePosition, "beamish", self.beamTileDamage, 99)
  end

  coroutine.yield()

  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    self:updateBeam()

    local dt = script.updateDt()
    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  self.aimLocked = false

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

  animator.resetTransformationGroup(self.armName .. "Beam")
  animator.scaleTransformationGroup(self.armName .. "Beam", {beamLength, 1}, {self.beamSourceOffset[1], self.beamSourceOffset[2] - self.beamHeight / 2})

  local particleRegion = {self.beamSourceOffset[1], self.beamSourceOffset[2], self.beamSourceOffset[1] + beamLength, self.beamSourceOffset[2]}
  animator.setParticleEmitterOffsetRegion(self.armName .. "Beam", particleRegion)

  return endPoint, beamCollision, beamLength
end
