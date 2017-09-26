require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Uppercut = WeaponAbility:new()

function Uppercut:init()
  self.freezeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function Uppercut:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
    mcontroller.controlApproachVelocity({0, 0}, 1000)
  end
end

-- used by fist weapon combo system
function Uppercut:startAttack()
  self:setState(self.windup)

  self.weapon.freezesLeft = 0
  self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function Uppercut:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function Uppercut:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: special
function Uppercut:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.2)
  
    local uppercutPower = { power = 0.25, timeToLive = 0.05, damageSourceKind = default, piercing = true }
    world.spawnProjectile("uppercutspecial", mcontroller.position(), activeItem.ownerEntityId(), {0, 1}, true, uppercutPower) 
    
  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("specialswoosh")
    local uppercutPower = { power = 0.25 }

    if self.stances.fire.velocity and math.abs(world.gravity(mcontroller.position())) > 0 then
      mcontroller.controlApproachVelocity({self.stances.fire.velocity[1] * self.weapon.aimDirection, self.stances.fire.velocity[2]}, 1000)
    end
  end)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
  
end

function Uppercut:uninit(unloaded)
  self.weapon:setDamage()
end
