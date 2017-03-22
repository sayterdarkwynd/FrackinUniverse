require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  activeItem.setScriptedAnimationParameter("markerImage", "/items/active/weapons/other/angryrocket/targetoverlay.png")
  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  storage.fireTimer = config.getParameter("primaryAbility").fireTime or 1
  self.recoilTimer = 0

  activeItem.setCursor("/cursors/reticle0.cursor")
  reset()
  
  setToolTipValues(config.getParameter("primaryAbility"))
end

function setToolTipValues(ability)
  activeItem.setInstanceValue("tooltipFields", {
    damagePerShotLabel = damagePerShot(ability) * ability.projectileCount,
    speedLabel = 1 / ability.fireTime,
    energyPerShotLabel = ability.energyUsage
  })
end

function update(dt, fireMode, shiftHeld)
	if deltatime==nil then
		deltatime=0
	end
	deltatime=deltatime+dt
	updateAim()
	if self.target ~= nil then
		if not world.entityExists(self.target) then
			self.target=nil
		end
	end
	
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	self.recoilTimer = math.max(self.recoilTimer - dt, 0)
	local ability = config.getParameter(fireMode.."Ability")
	
	if fireMode == "alt" then
		if lockTime==nil then
			lockTime=0
		end
		if prevFireMode~="alt" then
			animator.playSound("enterAimMode")
		end
		if storage.fireTimer == 0 and not status.resourceLocked("energy") and deltatime>1 then
			--sb.logInfo(lockTime)
			local newTarget = findTarget()
			if newTarget ~= false and newTarget~= self.target then
				lockTime=0
				reset()
				self.target=newTarget
				animator.playSound("targetAcquired1")
				activeItem.setScriptedAnimationParameter("entities", {self.target})
			elseif self.target~=nil and newTarget==self.target then
				lockTime=lockTime+deltatime
				if lockTime >= 2 then
					animator.playSound("targetAcquired2")
				else
					animator.playSound("targetAcquired1")
				end
				activeItem.setScriptedAnimationParameter("entities", {self.target})
			elseif self.target~=nil then
				if lockTime >= 2 then
					animator.playSound("targetAcquired2")
				else
					animator.playSound("targetAcquired1")
				end
			end
			deltatime=0
			--sb.logInfo(lockTime)
		end
		prevAbility=ability
		prevFireMode=fireMode
	elseif ability and storage.fireTimer <= 0 and not world.pointTileCollision(firePosition()) and status.overConsumeResource("energy", ability.energyUsage) then
		storage.fireTimer = ability.fireTime or 1
		primaryFire(ability)
		prevFireMode=fireMode
	elseif prevFireMode=="alt" and fireMode=="none" then
		if self.target ~= nil then
			if lockTime >= 2 then
				altFire(prevAbility)
			end
		else
			animator.playSound("disengage")
		end
		lockTime=0
		prevFireMode=fireMode
		reset()
	end
	activeItem.setRecoil(self.recoilTimer > 0)
end


function altFire(ability)
  local projectileId = fireProjectile(ability,{power = damagePerShot(ability),powerMultiplier = activeItem.ownerPowerMultiplier(),target = self.target,maxSpeed=70})
  world.callScriptedEntity(projectileId, "setTarget", self.target)
  status.overConsumeResource("energy", ability.energyUsage)
end

function primaryFire(ability)
  local params = {
    power = damagePerShot(ability),
	powerMultiplier = activeItem.ownerPowerMultiplier()
  }
  local projectileId = fireProjectile(ability,params)
end

function fireProjectile(ability,params)
	if ability.projectileType==nil then
		return
	end
	self.recoilTimer = ability.recoilTime or 0.12
	muzzleFlash()
	return world.spawnProjectile(ability.projectileType,firePosition(),activeItem.ownerEntityId(),aimVector(ability),false,params)
end

function muzzleFlash()
	animator.playSound("fire")
	animator.burstParticleEmitter("fireParticles")
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector(ability)
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(ability.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function damagePerShot(ability)
  return ability.baseDps
  * ability.fireTime
  * (self.baseDamageMultiplier or 1.0)
  * config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
  / ability.projectileCount
end


function reset()
  activeItem.setScriptedAnimationParameter("entities", {})
  self.target=nil
end


function findTarget()
  local nearEntities = world.entityQuery(activeItem.ownerAimPosition(), 3, { includedTypes = {"monster", "npc", "player"} })
	if nearEntities~=nil then
		nearEntities = util.filter(nearEntities,
			function(entityId)
				if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
					return false
				end
				if world.lineTileCollision(firePosition(), world.entityPosition(entityId)) then
					return false
				end
				return true
			end
		)
		if #nearEntities > 0 then
			return nearEntities[1]
		end
	end
	return false
end
