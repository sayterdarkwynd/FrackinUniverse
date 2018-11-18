require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Projectilepunch = WeaponAbility:new()

function Projectilepunch:init()
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))

  self.freezeTimer = 0
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function Projectilepunch:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
    mcontroller.controlApproachVelocity({0, 0}, 1000)
  end
end

-- used by fist weapon combo system
function Projectilepunch:startAttack()
  self:setState(self.windup)

  self.weapon.freezesLeft = 0
  self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function Projectilepunch:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function Projectilepunch:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: special
function Projectilepunch:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()
  if self.aimDirection < 0 then params.processing = "?flipx" end

  local projectileId = world.spawnProjectile(self.projectileType, firePosition(), activeItem.ownerEntityId(), {activeItemAnimation.ownerFacingDirection(), 0}, false, params)

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("weapon")

    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function Projectilepunch:uninit(unloaded)
  self.weapon:setDamage()
end
