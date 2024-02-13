require "/scripts/status.lua"

function init()
	if status.isResource("damageAbsorption") then
		self.resource="damageAbsorption"
	elseif status.isResource("shieldHealth") then
		self.resource="shieldHealth"
	else
		effectHandler=effect.addStatModifierGroup({{stat = "physicalResistance", amount = 1 },{stat = "electricResistance", amount = 0.5 },{stat = "poisonResistance", amount = 1 },{stat = "iceResistance", amount = 0.7 },{stat = "fireResistance", amount = 0.7 },{stat = "radioactiveResistance", amount = 0.6 },{stat = "shadowResistance", amount = 0.7 },{stat = "cosmicResistance", amount = 0.7 }})
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

		status.setResource(self.resource, self.shieldHealth)
		self.currentDA = 0
		self.active = true
		self.broke = false

		self.maxShieldHealth = self.shieldHealth
		self.shieldHealthPercent = self.shieldHealth / self.maxShieldHealth
		if self.shieldHealthPercent > 1.0 then
			self.shieldHealthPercent = 1
		end
	else
		self.legacy=true
		self.damageListener = damageListener("damageTaken", checkDamageLegacy)
	end
	if not self.legacy then
		self.duration=effect.duration()
	end
	self.initialized=true
end

function update(dt)
	if not self.initialized then return end
	if self.legacy then
		self.damageListener:update()
		animator.setAnimationState("aura", "on")
		setTransparency(1.0-(math.random()*0.25))
	else
		local dur=effect.duration()
		self.duration=self.duration-dt
		if (self.duration~=dur) and (math.abs(self.duration-dur)>(2*dt)) then
			init()
		end
		if self.active and not self.broke then
			self.damageListener:update()
			self.currentDA = status.resource(self.resource)
			setTransparency(self.shieldHealthPercent)
		elseif self.active then
			animator.playSound("break")
			self.active = false
		else
			effect.expire()
		end
	end
end

function uninit()
	animator.setAnimationState("aura", "off")
	if self.legacy then
		effect.removeStatModifierGroup(effectHandler)
		return
	end
	if not self.broke then
		status.modifyResource(self.resource, - self.shieldHealth)
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
	for _,notification in pairs(notifications) do
		if notification.targetEntityId == effect.sourceEntity() then
			if status.resourcePositive(self.resource) then
				self.shieldHealth = self.shieldHealth - (self.currentDA - status.resource(self.resource))
				self.shieldHealthPercent = self.shieldHealth / self.maxShieldHealth
				setTransparency(self.shieldHealthPercent)
				if self.shieldHealth > 0 then
					animator.playSound("block")
				else
					self.broke = true
				end
			else
				self.broke = true
			end
		end
	end
end

function checkDamageLegacy(notifications)
	for _,notification in pairs(notifications) do
		if notification.targetEntityId == effect.sourceEntity() then
			animator.playSound("block")
		end
	end
end
