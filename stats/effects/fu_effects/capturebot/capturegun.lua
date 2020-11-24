require "/scripts/util.lua"
require "/scripts/companions/util.lua"

function init()
	if world.entityType(entity.id()) ~= "monster" then
		effect.expire()
		return
	end

	local pass,result=pcall(world.callScriptedEntity,entity.id(),"config.getParameter","capturable")
	self.isCapturable=pass and result

	if not self.isCapturable or status.statPositive("captureImmunity") or status.statPositive("specialStatusImmunity") then
		effect.expire()
		return
	end

	effect.addStatModifierGroup({{stat = "deathbombDud", amount = 1}})
	effect.setParentDirectives(config.getParameter("directives", ""))

	self.isCapturable=world.callScriptedEntity(entity.id(),"config.getParameter","capturable")

	if (status.isResource("stunned")) and (not status.statPositive("stunImmunity")) and (not status.isResource("food")) then
		status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
		mcontroller.setVelocity({0, 0})
		mcontroller.controlModifiers({facingSuppressed = true,movementSuppressed = true})
	end
	self.usePercent=config.getParameter("usePercent")

	message.setHandler("podPower",podPower)
	message.setHandler("podSource",podSource)
end

function update(dt)
	if not self.isCapturable or world.entityType(entity.id()) ~= "monster" or status.statPositive("captureImmunity") or status.statPositive("specialStatusImmunity") then
		effect.expire()
		return
	else
		if (status.isResource("stunned")) and (not status.statPositive("stunImmunity")) and (not status.isResource("food")) then
			status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
			mcontroller.setVelocity({0, 0})
			mcontroller.controlModifiers({facingSuppressed = true,movementSuppressed = true})
		end

		if capturePromise and capturePromise:finished() and capturePromise:succeeded() and capturePromise:result() then
			self.pet=capturePromise:result()
		elseif (not capturePromise) or (capturePromise and capturePromise:finished()) then
			capturePromise=world.sendEntityMessage(entity.id(), "pet.attemptCapture",self.podSource)
		end

		if self and self.isCapturable and self.podPower and not (self.didDamage or self.pet) then
			local damage

			if self.usePercent then --alternative scaling: percentage
				damage=math.min(status.resource("health")-1.0,status.resourceMax("health")*self.podPower*0.01)
			else
				damage=math.max(0,math.min(self.podPower,status.resource("health")-1.0))
			end

			if damage > 0.0 then
				status.applySelfDamageRequest({damageType = "IgnoresDef",damage = damage,damageSourceKind = "default",sourceEntityId = self.podSource})
			end
			self.didDamage=true
		end

		if self.pet then
			if not blocker then blocker=config.getParameter("blocker","warpedcapture") end
			if not status.statPositive(blocker) then
				world.callScriptedEntity(entity.id(),"monster.setDropPool",nil)
				status.addPersistentEffect(blocker,{stat=blocker,amount=1})
				spawnFilledPod(self.pet)
			end
		end
	end
end

function uninit()
	if not self.isCapturable or world.entityType(entity.id()) ~= "monster" or status.statPositive("captureImmunity") or status.statPositive("specialStatusImmunity") then
		return
	elseif (status.isResource("stunned")) and (not status.statPositive("stunImmunity")) and (not status.isResource("food")) then
		status.setResource("stunned",0)
	end
end

function spawnFilledPod(pet)
	local pod = createFilledPod(pet)
	world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
end

function podPower(_,_,powerStats)
	self.podPower=math.max(0,powerStats.power * powerStats.powerMultiplier)
	self.didDamage=false
	return self.podPower
end

function podSource(_,_,source)
	self.podSource=source
	return self.podSource
end
