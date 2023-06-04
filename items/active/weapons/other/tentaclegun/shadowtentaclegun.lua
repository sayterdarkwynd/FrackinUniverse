require "/items/active/weapons/ranged/gunfire.lua"

TentacleGun = GunFire:new()

function TentacleGun:init()
  self.chains = {}

  self.cooldownTimer = 0

  self.weapon:setStance(self.stances.idle)
  self.weapon.onLeaveAbility = function()
    self:killProjectiles()
  end
end

function TentacleGun:killProjectiles()
  for _,chain in pairs(self.chains) do
    world.callScriptedEntity(chain.targetEntityId, "projectile.die")
  end
end

function TentacleGun:uninit()
  self:killProjectiles()
end

function TentacleGun:shouldFire()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot) and
      self.cooldownTimer == 0 and
      #self.chains < self.maxProjectiles and
      not status.resourceLocked("energy")
end

function TentacleGun:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self:shouldFire() and not self.weapon.currentAbility then
    self:setState(self.firing)
  end
end

function TentacleGun:firing()
  self.weapon:setStance(self.stances.fire)

  self:fire()

  while #self.chains > 0 do
    if self:shouldFire() then
      self:fire()
    end

    self:updateTentacles()
    coroutine.yield()
  end

  self.weapon:setStance(self.stances.idle)
end

function TentacleGun:fire()
  status.overConsumeResource("energy", self.energyUsage * self.fireTime)

  for _ = 1, math.min(self.projectileCount, self.maxProjectiles - #self.chains) do
    local projectileParameters = {
        damageTeam = world.entityDamageTeam(activeItem.ownerEntityId()),
        power = self:damagePerShot(),
        powerMultiplier = activeItem.ownerPowerMultiplier()
      }
    util.mergeTable(projectileParameters, self.projectileParameters)
    local projectileId = world.spawnProjectile(
        self.projectileType,
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(self.inaccuracy),
        self.projectileTracksUser or false,
        projectileParameters
      )
    self:addProjectile(projectileId)
  end

  animator.playSound(self.fireSound)

  self.cooldownTimer = self.fireTime
end

function TentacleGun:addProjectile(projectileId)
  local newChain = copy(self.chain)
  newChain.targetEntityId = projectileId

  newChain.startOffset = vec2.add(newChain.startOffset or {0,0}, self.weapon.muzzleOffset)

  local min = newChain.arcRadiusRatio[1]
  local max = newChain.arcRadiusRatio[2]
  newChain.arcRadiusRatio = (math.random() * (max - min) + min) * (math.random(2) * 2 - 3)

  table.insert(self.chains, newChain)
end

function TentacleGun:updateTentacles()
  self.chains = util.filter(self.chains, function (chain)
      return chain.targetEntityId and world.entityExists(chain.targetEntityId)
    end)

  for _,chain in pairs(self.chains) do
    local endPosition = world.entityPosition(chain.targetEntityId)
    local length = world.magnitude(endPosition, mcontroller.position())
    chain.arcRadius = chain.arcRadiusRatio * length

    if self.guideProjectiles then
      local target = activeItem.ownerAimPosition()
      local distance = world.distance(target, mcontroller.position())
      if self.maxLength and vec2.mag(distance) > self.maxLength then
        target = vec2.add(vec2.mul(vec2.norm(distance), self.maxLength), mcontroller.position())
      end
      world.callScriptedEntity(chain.targetEntityId, "setTargetPosition", target)
    end
  end

  activeItem.setScriptedAnimationParameter("chains", self.chains)
end

function TentacleGun:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (self.fireAngle or self.weapon.aimAngle) + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

