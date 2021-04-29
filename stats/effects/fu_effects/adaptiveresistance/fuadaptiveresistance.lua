function init()
	local cooldown=config.getParameter("cooldown") or 15
	self.cooldownMonster=config.getParameter("cooldownMonster") or cooldown
	self.cooldownNotMonster=config.getParameter("cooldownNotMonster") or cooldown
	self.absorb=config.getParameter("absorb",true)
	self.minThreshold=config.getParameter("minHPLoss",1)
	self.maxThreshold=config.getParameter("maxHPLoss")
	self.queryDamageSince=0
	self.lastHitWhen=0
	adaptiveresistancehandler=effect.addStatModifierGroup({})
	self.disable=config.getParameter("disable")
end

function update(dt)
	if not self.eType then self.eType=world.entityType(entity.id()) end
	if (self.eType~="monster") or ((self.cooldownTimer) and (self.cooldownTimer <= 0)) then
		local damageNotifications,nextStep=status.damageTakenSince(self.queryDamageSince)
		self.queryDamageSince=nextStep
		local wasHit=false
		for _,notification in pairs(damageNotifications) do
			if notification.damageSourceKind~="falling" then
				if (notification.healthLost >= (self.minThreshold or 1)) and (not self.maxThreshold or (notification.healthLost<=self.maxThreshold)) then
					if self.eType=="monster" and status.isResource("stunned") then
						status.setResource("stunned",0.1)
					end
					if self.absorb and (self.eType=="monster") then
						status.modifyResource("health",notification.damageDealt)
					end
					local monkey=root.elementalResistance(notification.damageSourceKind)
					if monkey then
						local element=monkey:lower():gsub("resistance","")
						element=element:sub(1,1):upper()..element:sub(2)
						if element==glitchelement then
							self.hitCount=math.min(9,(self.hitCount or 0)+1)
						else
							self.hitCount=1
						end
						glitchelement=element
						local resAmount=(self.disable and 0) or ((self.eType == "monster") and 1000) or ((self.hitCount or 1)*0.1)
						effect.setStatModifierGroup(adaptiveresistancehandler,{{stat=monkey,amount=resAmount}})
						self.cooldownTimer=((self.eType == "monster") and self.cooldownMonster) or self.cooldownNotMonster
						wasHit=true
						self.lastHitWhen=self.queryDamageSince
						break
					end
				end
			end
		end
		if not wasHit then
			if (self.eType=="monster") or (math.abs(self.queryDamageSince-self.lastHitWhen)/60.0)>=self.cooldownNotMonster then
				effect.setStatModifierGroup(adaptiveresistancehandler,{})
				glitchelement=nil
				glitchelementcolor=nil
			end
		end
	end
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