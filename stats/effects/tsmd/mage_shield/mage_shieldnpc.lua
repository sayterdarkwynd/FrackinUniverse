require "/scripts/status.lua"

function init()
  animator.setAnimationState("aura", "windup")
  self.damageListener = damageListener("damageTaken", checkDamage)
  
  self.shieldHealth = config.getParameter("shieldHealth")
  self.dangerHealth = self.shieldHealth * 0.2
  self.currentDA = 0
  self.shieldRemaining = self.shieldHealth
  self.active = true
  self.broke = false
end

function update(dt)
  if self.active then  
    self.damageListener:update()
    self.currentDA = self.shieldRemaining
    effect.addStatModifierGroup({
      {stat = "physicalResistance", amount = 0.5 },
      {stat = "electricResistance", amount = 0.5 },
      {stat = "poisonResistance", amount = 0.5 },
      {stat = "iceResistance", amount = 0.5 },
      {stat = "fireResistance", amount = 0.5 },
      {stat = "radioactiveResistance", amount = 0.5 },
      {stat = "shadowResistance", amount = 0.5 },
      {stat = "cosmicResistance", amount = 0.5 }
      })
  else  
    effect.expire()
  end
end

function uninit()
  animator.setAnimationState("aura", "off")
  if not self.broke then
    self.shieldRemaining = (self.shieldRemaining - self.shieldHealth)
  end
end

function checkDamage(notifications)
  for _,notification in pairs(notifications) do
    if notification.targetEntityId == effect.sourceEntity() then
      if self.shieldRemaining then
        animator.playSound("block")
        self.shieldHealth = self.shieldHealth - (self.currentDA - self.shieldRemaining)
        
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
