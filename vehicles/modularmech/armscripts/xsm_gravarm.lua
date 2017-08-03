require "/vehicles/modularmech/armscripts/base.lua"

BeamArm = MechArm:extend()

function BeamArm:init()
  self.state = FSM:new()
  self.beamActiveRadius = 2
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
  -- local f = animator.partPoint(self.armName,"fireOffset")
  -- if f then 
    -- world.debugText("%s",f,self:shoulderPosition(),"green")
    -- world.debugPoint(vec2.add(mcontroller.position(),f),"yellow")
    -- end
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
  end
end

function BeamArm:fireState()
-- initialize
  local stateTimer = 0--self.fireTime
  local soundTimer = 0
  local dt = script.updateDt()
  local weaponLocked = false
  local entityLocked = nil
  
  animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)--self.aimAngle

  self.aimLocked = self.lockAim
  self.newFirePosition = self.firePosition
  self.newFireAngle = self.aimAngle
  
  coroutine.yield()
  
-- update loop
  while self.isFiring do
    if not self:rayCheck(self.newFirePosition) then -- don't fire if sticking thru wall
      self.state:set(self.winddownState, self)
      return
    end
--    world.debugText("%s",util.angleDiff(self:fireAngle(),self.aimAngle),mcontroller.position(),"red")
    if soundTimer < 0 then soundTimer = 0.1 end
    if vec2.mag(vec2.sub(self:shoulderPosition(),self.newFirePosition))*2 < vec2.mag(vec2.sub(self:shoulderPosition(),self.aimPosition)) then
      self.newFirePosition = self:firePos()
      self.newFireAngle = self:fireAngle()
    else
      self.newFirePosition = self.firePosition
      self.newFireAngle = self.aimAngle
    end
    animator.rotateTransformationGroup(self.armName, self.newFireAngle, self.shoulderOffset)
    local endPoint, beamCollision, beamLength = self:updateBeam()

    if stateTimer <= 0 then
      stateTimer = self.fireTime
      local pullTo = self.mechWeapon2Mode ~= "pull" and self.aimPosition 
              or vec2.add(self.newFirePosition,vec2.mul(self:fireVector(),1.5))
      if pullTo then world.debugPoint(pullTo, "green") end
      
      local entityList = world.monsterQuery(endPoint,self.beamActiveRadius) or {}
      if #entityList > 0 and not entityLocked then
        entityLocked = entityList[1]
      end
      weaponLocked = entityLocked and world.entityExists(entityLocked) 
                  and vec2.mag(vec2.sub(self.newFirePosition,world.entityPosition(entityLocked))) < self.beamMaxRange 
                  and not beamCollision

      if weaponLocked then
        endPoint = world.entityPosition(entityLocked) or endPoint
        local v = entityLocked
        local diffX = (pullTo[1] - world.entityPosition(v)[1]) 
        local diffY = (pullTo[2] - world.entityPosition(v)[2])

        local velocity = {self.beamPullCoefficient * diffX, self.beamPullCoefficient * diffY}
--        world.callScriptedEntity(v, "mcontroller.setVelocity", velocity)
-- original code causes error :/
        local velOffs = vec2.mul(vec2.norm(velocity),2)
        local ppos = vec2.mag({diffX,diffY}) < 2 and vec2.add(world.entityPosition(v),{diffX,diffY}) or vec2.add(world.entityPosition(v),velOffs)
        world.spawnProjectile("xsmm_physics",ppos, self.driverId, {0,0}, false)
        if soundTimer <= dt then animator.playSound(self.armName .. "Locked") end
      else
        
        entityLocked = nil
        if soundTimer <= dt then animator.playSound(self.armName .. "Fire") end
      end
      local beamPstart = weaponLocked and self.beamStartProjectile or self.beamIndicatorStartProjectile
      local beamPmid = weaponLocked and self.beamProjectile or self.beamIndicatorProjectile
      local beamPend = weaponLocked and self.beamEndProjectile or self.beamCrosshair
      local beamPvel = mcontroller.zeroG() and mcontroller.velocity() or nil
      
      self:progressiveLineCollision(self.newFirePosition, endPoint, self.beamStep, beamPmid, beamPvel)
      world.spawnProjectile(beamPend, endPoint, self.driverId, {0, 0}, false,{referenceVelocity = beamPvel,onlyHitTerrain=true})
      world.spawnProjectile(beamPstart, self.newFirePosition, self.driverId, {0, 0}, false,{referenceVelocity = beamPvel,onlyHitTerrain=true})
    end

    stateTimer = stateTimer - dt
    soundTimer = soundTimer - dt
    coroutine.yield()
  end
-- end update
  self.aimLocked = false

  self.state:set(self.winddownState, self)
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
  local beamLength = math.min(vec2.mag(vec2.sub(self.newFirePosition,self.aimPosition)),self.beamMaxRange or 25)
  local endPoint = vec2.add(self.newFirePosition, vec2.mul(self:fireVector(), beamLength)) 

  local beamCollision = self:progressiveLineCollision(self.newFirePosition, endPoint, self.beamStep or 1)
  if not vec2.eq(beamCollision,endPoint) then
    endPoint = beamCollision
  else
    beamCollision = nil
  end


  return endPoint, beamCollision, beamLength
end

function BeamArm:progressiveLineCollision(startPoint, endPoint, stepSize, projectile, pVelocity)
  local dist = world.magnitude(startPoint, endPoint)
  local steps = math.floor(dist / stepSize)
  local normX = (endPoint[1] - startPoint[1]) / dist
  local normY = (endPoint[2] - startPoint[2]) / dist
  for i = 1, steps-1 do
    local p1 = { normX * i * stepSize + startPoint[1], normY * i * stepSize + startPoint[2]}
    local p2 = { normX * (i + 1) * stepSize + startPoint[1], normY * (i + 1) * stepSize + startPoint[2]}
    if projectile ~= nil then            
      world.spawnProjectile(projectile, math.midPoint(p1, p2), self.driverId, {normX, normY}, false,{speed=0,referenceVelocity=pVelocity,onlyHitTerrain=true})
    end
    if world.lineCollision(p1, p2, {"Null","Block","Dynamic"}) then
      return math.midPoint(p1, p2)
    end
  end
  return endPoint
end

function BeamArm:fireAngle()
  local baseAimVector = world.distance(self.aimPosition, self.newFirePosition)
  local aimAngle = vec2.angle(baseAimVector)

  if self.facingDirection == -1 then
    aimAngle = math.pi - aimAngle
  end

  aimAngle = util.angleDiff(0, aimAngle)
  aimAngle = math.max(self.rotationLimits[1], math.min(aimAngle, self.rotationLimits[2]))

  return aimAngle
end

function BeamArm:fireVector()
  local aimAngle = self:fireAngle()
  local aimVector = vec2.withAngle(aimAngle)
  aimVector[1] = aimVector[1] * self.facingDirection
  return aimVector
end

function BeamArm:firePos()
  local firePosition = vec2.rotate(self.fireOffset, self:fireAngle())
  firePosition[1] = firePosition[1] * self.facingDirection
  firePosition = vec2.add(self:shoulderPosition(), firePosition)
  return firePosition
end

function math.midPoint(coordA, coordB)
  local u = { 0.5 * (coordB[1] + coordA[1]), 0.5 * (coordB[2] + coordA[2]) }
  return u
end
