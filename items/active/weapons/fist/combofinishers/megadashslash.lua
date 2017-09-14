require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

DashSlash = WeaponAbility:new()

function DashSlash:init()
  self.freezeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function DashSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  if self.freezeTimer > 0 and not mcontroller.onGround() then
    mcontroller.controlApproachVelocity({0, 0}, 1000)
  end

  if self.damageListener then
    self.damageListener:update()
  end
end

-- used by fist weapon combo system
function DashSlash:startAttack()
  self:setState(self.windup)

  self.weapon.freezesLeft = 0
  self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function DashSlash:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function DashSlash:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.dash)
end

-- State: special
function DashSlash:dash()
  self.weapon:setStance(self.stances.dash)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")

  status.addEphemeralEffect("invulnerable", self.stances.dash.duration + 0.1)

  if self.burstParticlesOnHit then
    self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.damageConfig.damageSourceKind then
          animator.burstParticleEmitter(self.burstParticlesOnHit)          
          return
        end
      end
    end)
  end

  util.wait(self.stances.dash.duration, function()
    mcontroller.controlMove(self.weapon.aimDirection)
    mcontroller.controlApproachVelocity(self.weapon:faceVector(self.stances.dash.velocity), 2000)
   
    local damageArea = partDamageArea("specialswoosh")
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
    
 
    
  end)

  self.damageListener = nil

  mcontroller.setVelocity({0, 0})

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function DashSlash:uninit(unloaded)
  self.weapon:setDamage()
end
