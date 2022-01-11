require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.resourceCost1=config.getParameter("resourceCost1",0)
	self.resource1=config.getParameter("resource1","energy")
	self.resource1Over=config.getParameter("resource1Over","energy")
	self.resourceCost2=config.getParameter("resourceCost2",false)
	self.resource2=config.getParameter("resource2",0)
	self.resource2Over=config.getParameter("resource2Over",false)
	self.projectileSpit=config.getParameter("projectileSpit","coconut")
	self.projectileExplode=config.getParameter("projectileExplode","coconut")
	self.projectileExplode2=config.getParameter("projectileExplode2","coconut")
	self.fireRate1=config.getParameter("fireRate1",3)
	self.fireRate2=config.getParameter("fireRate2",3)
	self.projectile1BaseDamage=config.getParameter("projectile1BaseDamage",30)
	self.projectile1spreadcount=config.getParameter("projectile1spreadcount",10)
	self.projectile2Base=config.getParameter("projectile2Base",3)
	self.projectile1Debuff=config.getParameter("projectile1Debuff","weakpoison")
	self.projectile2RadiusForeground=config.getParameter("projectile2RadiusForeground",1)
	self.projectile2RadiusBackground=config.getParameter("projectile2RadiusBackground",1)
	self.projectile1BonusScalar=config.getParameter("projectile1BonusScalar",1.0)
	self.projectile1StatScalar=config.getParameter("projectile1StatScalar","maxHealth")
	self.projectile1StatScalarOffset=config.getParameter("projectile1StatScalarOffset",-100)
	self.projectile2BonusScalar=config.getParameter("projectile2BonusScalar",0.05)
	self.projectile2StatScalar=config.getParameter("projectile2StatScalar","maxHealth")
	self.projectile2StatScalarOffset=config.getParameter("projectile2StatScalarOffset",-100)
end

function activate(fireMode,down)
	if fireMode then
		if self.resource2Over then
			if not status.overConsumeResource(self.resource2,self.resourceCost2) then self.firetimer=0.05 return end
		else
			if not status.consumeResource(self.resource2,self.resourceCost2) then self.firetimer=0.05 return end
		end
	else
		if self.resource1Over then
			if not status.overConsumeResource(self.resource1,self.resourceCost1) then self.firetimer=0.05 return end
		else
			if not status.consumeResource(self.resource1,self.resourceCost1) then self.firetimer=0.05 return end
		end
	end
	local aimPos=tech.aimPosition()
	local direction=vec2.norm(world.distance(aimPos,entity.position()))
	local pParams={}
	if fireMode then--tile destroyer
		pParams.speed=50
		pParams.timeToLive=3
		pParams.physics="grenade"
		pParams.bounces=0
		local buffer=self.projectile2Base+math.max(0,(status.stat(self.projectile2StatScalar)+self.projectile2StatScalarOffset)*self.projectile2BonusScalar)--scales damage and duration
		--carrier's periodic actions. lua nesting makes for...complaints.
		local carrierPeriodicConfig={
			{
				time=0.5,
				action='explosion',
				foregroundRadius=self.projectile2RadiusForeground,
				backgroundRadius=self.projectile2RadiusBackground,
				explosiveDamageAmount=buffer,--projectile doesn't do damage but eh.
				harvestLevel = buffer,
				delaySteps=2
			}
		}
		pParams.actionOnReap = {
			{
				action = "projectile",
				time = 0.01,
				["repeat"] = false,
				type = self.projectileExplode2,
				config = {
					bounces=0,
					timeToLive=1,
					actionOnReap = {
						{
							action='projectile',
							time = 1,
							type = self.projectileExplode2,
							["repeat"] = false,
							config = {
								timeToLive=buffer,periodicActions=carrierPeriodicConfig
							}
						}
					}
				},
				angleAdjust = 0,
				inheritDamageFactor = 0.0,
				inheritSpeedFactor = 0.0
			}
		}
	else--debuff scaling based off player stats. uses duration as an argument, so requires a status effect coded around that.
		pParams.statusEffects={{effect=self.projectile1Debuff,duration=self.projectile1BaseDamage+math.max(0,((status.stat(self.projectile1StatScalar)+self.projectile1StatScalarOffset)*self.projectile1BonusScalar))}}
		pParams.actionOnReap={}
		pParams.speed=25
		pParams.timeToLive=15
		pParams.piercing=false
		for i=0,self.projectile1spreadcount-1 do
			table.insert(pParams.actionOnReap, {
				time = 0.1,
				["repeat"] = false,
				action = "projectile",
				type = self.projectileExplode,
				config = {statusEffects=pParams.statusEffects,timeToLive=1},
				angleAdjust = i*(360/self.projectile1spreadcount),
				inheritDamageFactor = 0.0,
				inheritSpeedFactor = 0.1
			}
		)
		end
	end
	animator.playSound("activate",fireMode and self.fireRate2 or self.fireRate1)
	self.firetimer=fireMode and self.fireRate2 or self.fireRate1
	world.spawnProjectile(self.projectileSpit,vec2.add(mcontroller.position(), {mcontroller.facingDirection(),(down and -0.3) or 0.6}),entity.id(),direction,false,pParams)
end

function update(args)
	self.firetimer = math.max(0, (self.firetimer or 0) - args.dt)
	if args.moves["special1"] and not status.resourceLocked("energy") then
		if self.firetimer == 0 then
			activate(not args.moves.run,args.moves.down)
		end
	else
		animator.stopAllSounds("activate")
	end
end