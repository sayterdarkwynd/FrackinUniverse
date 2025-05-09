require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"
require "/items/active/tagCaching.lua"
local foodThreshold=10--used by checkFood

function init()
	self.firetimer = 0
	self.rechargeDirectives = "?fade=CC22CCFF=0.1"
	self.rechargeEffectTime = 0.1
	self.rechargeEffectTimer = 0
	self.flashCooldownTimer = 0
	self.halted = 0
	self.currentBonus = 0
end

function activeFlight(foodValue,direction)
	status.removeEphemeralEffect("wellfed")
	local movement=mcontroller.velocity()
	world.spawnProjectile("veluuclaw", spawnPos(), entity.id(),direction, false, { speed=(8+math.sqrt((movement[1]^2)+(movement[2]^2))), power = (((self.currentBonus	+ (foodValue / 20) + (status.resource("health") / 30)) + world.threatLevel())*(((status.stat("powerMultiplier")-1.0)*0.5)+1.0))})
	if self.currentBonus < 6 then
		self.currentBonus = self.currentBonus +1
	else
		animator.playSound("powerAttack")
		self.currentBonus = 0
	end
end

function aimVector(x,y,run)
	local banana=(run and mcontroller.facingDirection()) or 0
	return {(x+banana)*2,y*2}
end

function chargeUp()
	if self.halted == 0 then
		 self.halted = 1
	end
end

function spawnPos()
	local sP=mcontroller.position()
	mP=status.statusProperty("mouthPosition")
	if mP then
		sP=vec2.add(sP,mP)
	end
	return sP
end

function update(args)
	tagCaching.update()
	self.firetimer = math.max(0, self.firetimer - args.dt)

	if self.flashCooldownTimer > 0 then
		self.flashCooldownTimer = math.max(0, self.flashCooldownTimer - args.dt)
		if self.flashCooldownTimer <= 2 then
			chargeUp()
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

	if args.moves["special1"] and self.firetimer == 0 and (not tagCaching.mergedCache["weapon"]) then
		local upDown=((args.moves["down"] and -1) or 0) + ((args.moves["up"] and 1) or 0)
		local leftRight=((args.moves["left"] and -1) or 0) + ((args.moves["right"] and 1) or 0)
		local foodValue=checkFood() or foodThreshold
		if foodValue > 10 then
			status.addEphemeralEffects{{effect = "foodcostclaw", duration = 0.01}}
		else
			status.overConsumeResource("energy", 3)
		end
		self.firetimer = 0.3
		activeFlight(foodValue,aimVector(leftRight,upDown,args.moves["run"]))
		--activeFlight(foodValue)
		self.dashCooldownTimer = 0.3
		self.flashCooldownTimer = 0.3
		self.halted = 0
	end
end
