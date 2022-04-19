require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

TheaLightningFire = WeaponAbility:new()

function TheaLightningFire:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("weapon", "idle")

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("lightning", {})
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
	animator.setAnimationState("weapon", "idle")
  end
end

function TheaLightningFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function TheaLightningFire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) do
	--Play the weapon's active animation
	animator.setAnimationState("weapon", "active")

    local beamStart = self:firePosition()
	--Beam End for checking terrain collision
    local beamEndGround = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.lightningDistanceGround))
	--Beam End for checking enemy collision
	local beamEndEnemies = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.lightningDistanceEnemies))
	--Beam length for general purposes
    local beamLength = self.lightningDistanceGround

	local beamHasCollision = false

	--Check for tile collision along aline
    local collidePoint = world.lineCollision(beamStart, beamEndGround)
    if collidePoint then
      local beamEnd = collidePoint
      beamLength = world.magnitude(beamStart, beamEnd)
	  beamHasCollision = true
    end

	--Check for enemy collision along line
	local targets = world.entityLineQuery(beamStart, beamEndEnemies, {
      withoutEntityId = activeItem.ownerEntityId(),
      includedTypes = {"creature"},
      order = "nearest"
    })
	--Set the default distance to nearest target to max search distance
	local nearestTargetDistance = self.lightningDistanceEnemies
	for _, target in ipairs(targets) do
	  --Make sure we can damage the targeted entity
	  if world.entityCanDamage(activeItem.ownerEntityId(), target) then
		local beamEnd = world.entityPosition(target)
		--Make sure we have line of sight
		if not world.lineCollision(beamStart, beamEnd) then
		  local targetDistance = world.magnitude(beamStart, beamEnd)
		  --If the target currently being processed is closer than the nearest target found so far, make this target the nearest target
		  if targetDistance < nearestTargetDistance then
			nearestTargetDistance = targetDistance
			beamLength = world.magnitude(beamStart, beamEnd)
			beamHasCollision = true
		  end
		end
	  end
	end

	if beamHasCollision == true then
	  self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.fireTime)
	end

	--Draw lightning using these parameters
	-- amount, width, forks, branching, color, length, hasCollision(Bool)
	self:setLightning(self.lightningAmount, self.lightningWidth, self.lightningForks, self.lightningBranchingAmount, self.lightningColour, beamLength, beamHasCollision)

    coroutine.yield()
  end

  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function TheaLightningFire:setLightning(amount, width, forks, branching, color, length, collision)
  local lightning = {}
  for _ = 1, amount do
    local bolt = {
      minDisplacement = 0.125,
      forks = forks,
      forkAngleRange = 0.75,
      width = width,
      color = color
    }
	bolt.itemStartPosition = self.weapon.muzzleOffset
	if collision == true then
	  bolt.itemEndPosition = vec2.add(self.weapon.muzzleOffset, {length, 0})
	else
	  bolt.itemEndPosition = vec2.add(self.weapon.muzzleOffset, self.lightningTargetOffset)
	end
    bolt.displacement = 1
    table.insert(lightning, bolt)
  end
  activeItem.setScriptedAnimationParameter("lightning", lightning)
end

function TheaLightningFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function TheaLightningFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function TheaLightningFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function TheaLightningFire:uninit()
  self:reset()
end

function TheaLightningFire:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("lightning", {})
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
end
