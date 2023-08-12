local handler

function init()
	activateVisualEffects()
	script.setUpdateDelta(1)
	setParticleConfig(0)
	self.damagePercent=config.getParameter("percentHealthDamagePerTick",-0.01)
	self.baseDuration=config.getParameter("baseDuration",60)
	self.poisonStacks=self.poisonStacks or 1
	local dur=effect.duration()
	if self.duration then
		self.poisonStacks=self.poisonStacks+1
	end
	self.duration=self.duration or math.min(60,dur)
	handler=effect.addStatModifierGroup({})
end

function update(dt)
	setParticleConfig(dt)

	local dur=effect.duration()
	self.duration=self.duration-dt
	if (self.duration~=dur) and (math.abs(self.duration-dur)>(2*dt)) then
		self.poisonStacks=(self.poisonStacks or 0)+1
		self.duration=dur
		if self.weaknessStacks and self.weaknessStacks>0 then
			kill()
		end
	elseif (self.poisonStacks>1) and (((self.duration <= (self.baseDuration*0.5)+(dt/5)) and (self.duration >= (self.baseDuration*0.5)-(dt/5))) or ((self.duration <= (self.baseDuration*0.25)+(dt/5)) and (self.duration >= (self.baseDuration*0.25)-(dt/5)))) then
		self.poisonStacks=math.ceil(self.poisonStacks/1)
	end

	local damagePct=self.damagePercent*self.poisonStacks*dt
	local currentHP=status.resource("health")
	local maxHP=status.resourceMax("health")
	if ((maxHP*damagePct)+currentHP)<1 then
		damagePct=(currentHP-1)/maxHP
		self.weaknessStacks=(self.weaknessStacks or 0)+dt
	else
		self.weaknessStacks=math.max(0,(self.weaknessStacks or 0)-dt)
	end
	local penaltyBuffer=((10-(self.poisonStacks+self.weaknessStacks))/10)
	if (maxHP*penaltyBuffer)<1 then
		kill()
	else
		effect.setStatModifierGroup(handler,{
			{stat="maxHealth",effectiveMultiplier=penaltyBuffer},
			{stat="maxEnergy",effectiveMultiplier=penaltyBuffer},
			{stat="powerMultiplier",effectiveMultiplier=penaltyBuffer},
			{stat="protection",effectiveMultiplier=penaltyBuffer},
			{stat="healingBonus",amount=penaltyBuffer-1}
		})
		status.modifyResourcePercentage("health",damagePct)
		world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
	end
end

function kill()
	effect.setStatModifierGroup(handler,{{stat="poisonResistance",effectiveMultiplier=0}})
	status.applySelfDamageRequest({damageType = "IgnoresDef",damage = math.huge,damageSourceKind = "bioweapon",sourceEntityId = entity.id()})
end

function setParticleConfig(dt)
	if not particleConfig then
		particleConfig={type = "textured",image = "/animations/blur/blur2.png",destructionAction = "fade",size = 1,layer = "front",variance = {rotation=360,initialVelocity = {0.0, 0.0}}}
	end
	particleConfig.position=entity.position()
	particleConfig.timeToLive = dt*7.5
	particleConfig.destructionTime = dt*3.75
end

function activateVisualEffects()
	--animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	--animator.setParticleEmitterActive("smoke", true)
	effect.setParentDirectives("fade=edcd5c=0.2")
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end
