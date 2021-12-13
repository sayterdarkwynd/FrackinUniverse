require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=15--used by checkFood

function init()
	self.firetimer = 0
	self.rechargeDirectives = "?fade=CC1122FF=0.25"
	self.rechargeEffectTime = 0.1
	self.rechargeEffectTimer = 0
	self.flashCooldownTimer = 0
	self.halted = 0
end

function activeFlight(foodValue)
	animator.playSound("activate",3)
	animator.playSound("recharge")
	status.removeEphemeralEffect("wellfed")
	world.spawnProjectile("fumechbladeshadowswoosh", mcontroller.position(), entity.id(), aimVector(), false, {power = ((foodValue /60) + (status.resource("energy")/150) + (27 - (getLight()/2))),knockback = 50})
end

function aimVector()
	local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function update(args)
	self.firetimer = math.max(0, self.firetimer - args.dt)

	if self.flashCooldownTimer > 0 then
		self.flashCooldownTimer = math.max(0, self.flashCooldownTimer - args.dt)
		if self.flashCooldownTimer <= 2 then
			if self.halted == 0 then
				self.halted = 1
				animator.playSound("chargeUp")
				animator.setSoundVolume("chargeUp",0.5,0)
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

	if args.moves["special1"] and status.overConsumeResource("energy", 0.001) and self.firetimer == 0 then
		local foodValue=checkFood() or foodThreshold
		if foodValue > foodThreshold then
			status.addEphemeralEffects{{effect = "foodcostshadow", duration = 0.5}}
		else
			status.overConsumeResource("energy", 40)
		end
		self.firetimer = 3
		activeFlight(foodValue)
		self.dashCooldownTimer = 3
		self.flashCooldownTimer = 3
		self.halted = 0
	else
		animator.stopAllSounds("activate")
	end
end