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

  self.playerId = entity.id()
  self.maxShieldHealth = self.shieldHealth 
  self.shieldHealthPercent = self.shieldHealth / self.maxShieldHealth
  if self.shieldHealthPercent > 1.0 then
    self.shieldHealthPercent = 1
  end  
  self.barName = "mageShieldBar"
  self.barColor = {250,0,250,200}
  self.timerReloadBar = 0
  
end

function update(dt) 
  self.timerReloadBar = self.timerReloadBar + dt
  if (self.timerReloadBar >=5) then
    self.timerReloadBar = 5
  end
  if (self.timerReloadBar == 5) then -- is reload bar timer expired?
    world.sendEntityMessage(self.playerId,"removeBar","mageShieldBar")   --clear ammo bar  
    self.timerReloadBar = 0
  end

  if self.active then  
    self.damageListener:update()
    self.currentDA = status.resource("damageAbsorption")
  else  
    effect.expire()
  end
end

function uninit()
  animator.setAnimationState("aura", "off")
  if not self.broke then
    status.modifyResource("damageAbsorption", - self.shieldHealth)
  else
    world.sendEntityMessage(self.playerId,"removeBar","mageShieldBar")   --clear ammo bar  
  end
end

function checkDamage(notifications)
  	world.sendEntityMessage(
  	  self.playerId,
  	  "setBar",
  	  "mageShieldBar",
  	  self.shieldHealthPercent,
  	  self.barColor
	) 
  for _,notification in pairs(notifications) do
    if notification.targetEntityId == effect.sourceEntity() then
      if status.resourcePositive("damageAbsorption") then
        animator.playSound("block")
        
        self.shieldHealth = self.shieldHealth - (self.currentDA - status.resource("damageAbsorption"))
        self.shieldHealthPercent = self.shieldHealth / self.maxShieldHealth
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
