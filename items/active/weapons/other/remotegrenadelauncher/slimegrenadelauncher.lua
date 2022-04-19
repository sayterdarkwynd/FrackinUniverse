require "/scripts/vec2.lua"
require "/scripts/slimepersonglobalfunctions.lua"


function init()
  -- scale damage and calculate energy cost
  self.pType = config.getParameter("projectileType")
  self.pParams = config.getParameter("projectileParameters", {})
  self.pParams.power = self.pParams.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  self.energyPerShot = config.getParameter("energyUsage")

  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  storage.fireTimer = storage.fireTimer or 0
  self.recoilTimer = 0
  getSkinColorOnce = 0

  storage.activeProjectiles = storage.activeProjectiles or {}
  updateCursor()
end

function activate(fireMode, shiftHeld)
  if fireMode == "alt" then
    triggerProjectiles()
  end
end


function update(dt, fireMode, shiftHeld)
  if getSkinColorOnce == 0 then
        getSkinColorOnce = 1
        local result = world.entityPortrait(activeItem.ownerEntityId(),"full")
        local i = 1
        local done = 0
        while i < 12 do

                if string.find(sb.printJson(result[i].image), "head") ~= nil then
                    local bodyColor = sb.printJson(result[i].image)
                    bodyColor = bodyColor:sub(2,-2)
                    local splited = bodyColor:split("?")
                    animator.setGlobalTag("skinColor", "?" .. splited[2])
					activeItem.setInventoryIcon("/items/active/weapons/other/remotegrenadelauncher/slimegrenadelauncher.png".."?" .. splited[2])

                    done = done + 1
                end


                if string.find(sb.printJson(result[i].image), "hair") ~= nil then
                    local hairColor = sb.printJson(result[i].image)
                    hairColor = hairColor:sub(2,-2)
                    local splited = hairColor:split("?")
                    animator.setGlobalTag("hairColor", "?" .. splited[2])

                    done = done + 1
                end

                if done == 2 then
                    i = 13
                end
            i = i + 1
        end
    end

  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)
  self.recoilTimer = math.max(self.recoilTimer - dt, 0)

  if fireMode == "primary"
      and storage.fireTimer <= 0
      and not world.pointTileCollision(firePosition())
      and status.overConsumeResource("energy", self.energyPerShot) then

    storage.fireTimer = config.getParameter("fireTime", 1.0)
    fire()
  end

  activeItem.setRecoil(self.recoilTimer > 0)

  updateProjectiles()
  updateCursor()
    if self.handGrip == "wrap" then
    activeItem.setOutsideOfHand(self:isFrontHand())
  elseif self.handGrip == "embed" then
    activeItem.setOutsideOfHand(not self:isFrontHand())
  elseif self.handGrip == "outside" then
    activeItem.setOutsideOfHand(true)
  elseif self.handGrip == "inside" then
    activeItem.setOutsideOfHand(false)
  end
end

function updateCursor()
  if #storage.activeProjectiles > 0 then
    activeItem.setCursor("/cursors/chargeready.cursor")
  else
    activeItem.setCursor("/cursors/reticle0.cursor")
  end
end

function uninit()
getSkinColorOnce = 0
  for _, projectile in ipairs(storage.activeProjectiles) do
    world.callScriptedEntity(projectile, "setTarget", nil)
  end
end

function fire()
  self.pParams.powerMultiplier = activeItem.ownerPowerMultiplier()
  local projectileId = world.spawnProjectile(
      self.pType,
      firePosition(),
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      self.pParams
    )
  if projectileId then
    storage.activeProjectiles[#storage.activeProjectiles + 1] = projectileId
  end
  animator.burstParticleEmitter("fireParticles")
  animator.playSound("fire")
  self.recoilTimer = config.getParameter("recoilTime", 0.12)
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function updateProjectiles()
  local newProjectiles = {}
  for _, projectile in ipairs(storage.activeProjectiles) do
    if world.entityExists(projectile) then
      newProjectiles[#newProjectiles + 1] = projectile
    end
  end
  storage.activeProjectiles = newProjectiles
end

function triggerProjectiles()
  if #storage.activeProjectiles > 0 then
    animator.playSound("trigger")
  end
  for _, projectile in ipairs(storage.activeProjectiles) do
    world.callScriptedEntity(projectile, "trigger")
  end
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end
