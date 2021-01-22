require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
	self.active=false
	self.available = true
	self.firetimer = 0
	self.rechargeDirectives = "?fade=CC22CCFF=0.1"
	self.rechargeDirectivesNil = nil
	self.rechargeEffectTime = 0.1
	self.rechargeEffectTimer = 0
	self.flashCooldownTimer = 0
	self.halted = 0
	checkFood()
end

function uninit()

end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function checkFood()
	local foodValue=15
	if status.isResource("food") then
		foodValue = status.resource("food")
	end
	return foodValue
end

function activeFlight()
	world.spawnProjectile("hunterclaw", mcontroller.position(), entity.id(), aimVector(), false, { power = (((checkFood() / 20) + (status.resource("health") / 30)) + world.threatLevel())*(((status.stat("powerMultiplier")-1.0)*0.5)+1.0)})
end

function aimVector()
	local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function update(args)
	local primaryItem = world.entityHandItem(entity.id(), "primary")
	local altItem = world.entityHandItem(entity.id(), "alt")
	self.firetimer = math.max(0, self.firetimer - args.dt)

	if self.flashCooldownTimer > 0 then
		self.flashCooldownTimer = math.max(0, self.flashCooldownTimer - args.dt)
		if self.flashCooldownTimer <= 2 then
			if self.halted == 0 then
				self.halted = 1
			end
		end

		if self.flashCooldownTimer == 0 then
			self.rechargeEffectTimer = self.rechargeEffectTime
			tech.setParentDirectives(self.rechargeDirectives)
			animator.playSound("refire")
		end
	end

	if self.rechargeEffectTimer > 0 then
		self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
		if self.rechargeEffectTimer == 0 then
			tech.setParentDirectives()
		end
	end

	if args.moves["special1"] and self.firetimer == 0 and not (primaryItem and root.itemHasTag(primaryItem, "weapon")) and not (altItem and root.itemHasTag(altItem, "weapon")) then
		if checkFood() > 10 then
			status.addEphemeralEffects{{effect = "foodcostclaw", duration = 0.005}}
		else
			status.overConsumeResource("energy", 3)
		end
		self.firetimer = 0.3
		activeFlight()
		self.dashCooldownTimer = 0.3
		self.flashCooldownTimer = 0.3
		self.halted = 0
	end
end