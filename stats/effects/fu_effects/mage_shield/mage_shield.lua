require "/scripts/status.lua"

function init()
  animator.setAnimationState("aura", "windup")
  self.damageListener = damageListener("damageTaken", checkDamage)
  
  self.shieldHealth = config.getParameter("shieldHealth")
  self.dangerHealth = self.shieldHealth * 0.2
  status.giveResource("damageAbsorption", 0)
  status.setResource("damageAbsorption", 0)
  status.modifyResource("damageAbsorption", self.shieldHealth)
  self.currentDA = 0
  self.active = true
  self.broke = false
end

function update(dt)

  if self.active then  
    self.damageListener:update()
    
    self.currentDA = status.resource("damageAbsorption")
  else  
    effect.expire()
  end
end

function uninit()
  animator.setAnimationState("aura", "off")
  -- what if you get damage absorption from other effect?
  -- status.setResource("damageAbsorption", 0)
  
  if not self.broke then
    
    status.modifyResource("damageAbsorption", - self.shieldHealth)
  end
end

function checkDamage(notifications)
  for _,notification in pairs(notifications) do
    if notification.targetEntityId == effect.sourceEntity() then
      if status.resourcePositive("damageAbsorption") then
        animator.playSound("block")
        self.shieldHealth = self.shieldHealth - (self.currentDA - status.resource("damageAbsorption"))
        if self.shieldHealth <= self.dangerHealth then
          -- TODO: about to be broke
        end
      else
        animator.playSound("break")
        self.broke = true
        self.active = false
      end
      return
    end
  end
end
