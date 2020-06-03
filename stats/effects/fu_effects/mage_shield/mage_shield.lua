require "/scripts/status.lua"

function init()
  if status.isResource("damageAbsorption") then
	self.resource="damageAbsorption"
  elseif status.isResource("shieldHealth") then
    self.resource="shieldHealth"
  else
	--shitty copout for actual functionality, left behind for cases that shouldnt exist
    effectHandler=effect.addStatModifierGroup({{stat = "physicalResistance", amount = 1 },{stat = "electricResistance", amount = 0.5 },{stat = "poisonResistance", amount = 1 },{stat = "iceResistance", amount = 0.7 },{stat = "fireResistance", amount = 0.7 },{stat = "radioactiveResistance", amount = 0.6 },{stat = "shadowResistance", amount = 0.7 },{stat = "cosmicResistance", amount = 0.7 }}) 
    --effect.expire()
  end
  animator.setGlobalTag("effectDirectives","?multiply=FFFFFF00")
  animator.setAnimationState("aura", "windup")
  if self.resource then
	  self.damageListener = damageListener("damageTaken", checkDamage)
	  
	  self.shieldHealth = config.getParameter("shieldHealth")
	  self.usePercentHealth = config.getParameter("shieldUsesPercentHealth")
	  if self.usePercentHealth then
		self.shieldHealth=status.stat("maxHealth")*self.shieldHealth
	  end
	  
	  self.dangerHealth = self.shieldHealth * 0.2
	  status.setResource(self.resource, self.shieldHealth)
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
	  
	  self.initialized=true
  end
end

function update(dt) 
  if not self.initialized then return end
  self.timerReloadBar = self.timerReloadBar + dt
  if (self.timerReloadBar >=5) then
    self.timerReloadBar = 5
    world.sendEntityMessage(self.playerId,"removeBar","mageShieldBar")   --clear ammo bar 
  end
  if (self.timerReloadBar == 5) then -- is reload bar timer expired?
    world.sendEntityMessage(self.playerId,"removeBar","mageShieldBar")   --clear ammo bar  
    self.timerReloadBar = 0
  end

  if self.active and status.resourcePositive(self.resource) then  
    self.damageListener:update()
    self.currentDA = status.resource(self.resource)
	setTransparency(self.shieldHealthPercent)
  elseif self.active then
        animator.playSound("break")
        self.broke = true
        self.active = false
  else
    effect.expire()
  end
end

function uninit()
  animator.setAnimationState("aura", "off")
	if not self.initialized then 
		effect.removeStatModifierGroup(effectHandler)
		return
	end
  if not self.broke then
    status.modifyResource(self.resource, - self.shieldHealth)
  else
    world.sendEntityMessage(self.playerId,"removeBar","mageShieldBar")   --clear ammo bar  
  end
end


function setTransparency(rsp)
		if rsp>1.0 then rsp=1.0 elseif rsp<0 then rsp=0 end
		self.opacity=math.floor(rsp*255)
		self.opacity=string.format("%x",self.opacity)
		if string.len(self.opacity)==1 then
			self.opacity="0"..self.opacity
		end
		animator.setGlobalTag("effectDirectives","?multiply=FFFFFF"..self.opacity)
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
      if status.resourcePositive(self.resource) then
        animator.playSound("block")
        
        self.shieldHealth = self.shieldHealth - (self.currentDA - status.resource(self.resource))
        self.shieldHealthPercent = self.shieldHealth / self.maxShieldHealth
		--effect.setParentDirectives(string.format("?fade=%s",self.shieldHealthPercent))
		setTransparency(self.shieldHealthPercent)
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
