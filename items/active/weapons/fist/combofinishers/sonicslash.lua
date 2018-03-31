require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

SonicSlash = WeaponAbility:new()

function SonicSlash:init()
  self.freezeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function SonicSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
    mcontroller.controlApproachVelocity({0, 0}, 1000)
  end
end

-- used by fist weapon combo system
function SonicSlash:startAttack()
  self:setState(self.windup)

  self.weapon.freezesLeft = 0
  self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function SonicSlash:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function SonicSlash:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: special
function SonicSlash:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("specialswoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)
  
      local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
	local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount(),
	speed = 60
  }
  world.spawnProjectile("sonic", position, activeItem.ownerEntityId(), self:aimVector(), false, params)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function SonicSlash:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function SonicSlash:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function SonicSlash:uninit(unloaded)
  self.weapon:setDamage()
end
