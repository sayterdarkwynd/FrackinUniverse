require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=15--used by checkFood

function init()
	math.randomseed(util.seedTime())
end

function activeFlight(shiftHeld)
	local aimPos=tech.aimPosition()
	local direction=shiftHeld and {0,0} or vec2.norm(world.distance(aimPos,entity.position()))
	status.removeEphemeralEffect("wellfed")
	local damageConfig = { power = 2 + (((checkFood() or foodThreshold) /20) + (status.resource("energy")/50) + (status.stat("protection") /120)) * (1 + status.stat("bombtechBonus"))} -- add tech bonus damage from armor etc with self.bonusDamage
	animator.playSound("activate",3)
	animator.playSound("recharge")
	animator.setSoundVolume("activate", 0.5,0)
	animator.setSoundVolume("recharge", 0.375,0)
	world.spawnProjectile("fuenergyshardplayertech", self.mouthPosition, entity.id(), {direction[1]+((math.random()-0.5)*0.35),direction[2]+((math.random()-0.5)*0.35)}, false, damageConfig)
	--[[if not self.fed then
		local maxVal=17
		local bonusRange=2
		local random1=math.floor(math.random(1,maxVal))
		if random1>=(maxVal-bonusRange) then
			random1=maxVal-random1
			if shiftHeld then
				local random2=math.floor(math.random(1,maxVal))
				if random2>=(maxVal-bonusRange) then
					random1=random1+(maxVal-random2)
				end
			end
			for i=1,random1 do
				damageConfig.power=damageConfig.power*0.5
				world.spawnProjectile("fuenergyshardplayertech", self.mouthPosition, entity.id(), {direction[1]+((math.random()-0.5)*0.35),direction[2]+((math.random()-0.5)*0.35)}, false, damageConfig)
			end
		end
	end]]
end

function update(args)
	self.mouthPosition = vec2.add(mcontroller.position(), {mcontroller.facingDirection(),(args.moves["down"] and -0.7) or 0.15})
	self.firetimer = math.max(0, (self.firetimer or 0) - args.dt)
	self.fed=((checkFood() or foodThreshold) > foodThreshold)

	if args.moves["special1"] and status.overConsumeResource("energy", 0.001) then
		if self.fed then
			status.addEphemeralEffects{{effect = "foodcostfiretech", duration = 0.001}}
		else
			status.overConsumeResource("energy", 0.25)
		end

		if self.firetimer == 0 then
			self.firetimer = 0.1
			activeFlight(not args.moves["run"])
		end

	else
		animator.stopAllSounds("activate")
	end
end