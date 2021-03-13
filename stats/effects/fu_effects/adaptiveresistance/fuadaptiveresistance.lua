function init()
	self.cooldown=config.getParameter("cooldown") or 15
	self.absorb=config.getParameter("absorb",true)
	self.minThreshold=config.getParameter("minHPLoss",1)
	self.maxThreshold=config.getParameter("maxHPLoss")
	self.queryDamageSince=0
	adaptiveresistancehandler=effect.addStatModifierGroup({})
end

function update(dt)
	if (self.cooldownTimer) and (self.cooldownTimer <= 0) then
		effect.setStatModifierGroup(adaptiveresistancehandler,{})
		glitchelement=nil
		glitchelementcolor=nil
		local damageNotifications,nextStep=status.damageTakenSince(self.queryDamageSince)
		self.queryDamageSince=nextStep
		for _,notification in pairs(damageNotifications) do
			if (notification.healthLost >= (self.minThreshold or 1)) and (not self.maxThreshold or (notification.healthLost<=self.maxThreshold)) then
				if status.isResource("stunned") then
					status.setResource("stunned",0.1)
				end
				if self.absorb then
					status.modifyResource("health",notification.damageDealt)
				end
				local monkey=root.elementalResistance(notification.damageSourceKind)
				if monkey then
					if world.entityType(entity.id())=="monster" then
						glitchelement=monkey:lower():gsub("resistance","")
						glitchelement=glitchelement:sub(1,1):upper()..glitchelement:sub(2)
					end
					effect.setStatModifierGroup(adaptiveresistancehandler,{{stat=monkey,amount=1000}})
					self.cooldownTimer=self.cooldown
					break
				end
			end
		end
	else
		if glitchelement then
			glitchelementcolor=glitchelementcolor or {math.random()*255,math.random()*255,math.random()*255,255}
			for i=1,3 do
				glitchelementcolor[i]=glitchelementcolor[i]+((math.random()-0.5)*10)
				if glitchelementcolor[i]>255 then glitchelementcolor[i]=glitchelementcolor[i]-255
				elseif glitchelementcolor[i]<0 then glitchelementcolor[i]=255+glitchelementcolor[i]
				end
			end
			indicatorParticle(entity.position(),glitchelement,dt,glitchelementcolor)
		end
		self.cooldownTimer=math.max(0,(self.cooldownTimer or 0) - dt)
	end
end

function uninit()
	effect.removeStatModifierGroup(adaptiveresistancehandler)
end

function indicatorParticle(position,text,duration,color)
	world.spawnProjectile("invisibleprojectile",position,0,{0,0},false,{
		timeToLive=0,damageType="NoDamage",actionOnReap={{
					action="particle",
					specification={
						text=text or "",color=color or {0,0,0,255},destructionImage="/particles/acidrain/1.png",destructionAction="fade",destructionTime=duration or 0.8,
						layer="front",position={0,3},size=0.7,approach={0,20},initialVelocity={0,0.8},finalVelocity={0,0.5},angularVelocity=0,flippable=false,timeToLive=duration*2 or 2,rotation=0,type="text"
					}
			}}
	})
end