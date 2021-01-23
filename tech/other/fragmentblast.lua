require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
local foodThreshold=15

function init()
	math.randomseed(util.seedTime())
end

function checkFood()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resource("food")) or foodThreshold
end

function activeFlight(direction)
	status.removeEphemeralEffect("wellfed")
	local damageConfig = { power = 2 + ((checkFood() /20) + (status.resource("energy")/50) + (status.stat("protection") /120)) * (1 + status.stat("bombtechBonus")), damageSourceKind = "fire" } -- add tech bonus damage from armor etc with self.bonusDamage
	animator.playSound("activate",3)
	animator.playSound("recharge")
	animator.setSoundVolume("activate", 0.5,0)
	animator.setSoundVolume("recharge", 0.375,0)
	--world.spawnProjectile("fuenergyshardplayertech", self.mouthPosition, entity.id(), {math.random(-360,360),math.random(-360,360)}, false, damageConfig)
	world.spawnProjectile("fuenergyshardplayertech", self.mouthPosition, entity.id(), direction, false, damageConfig)
end

function aimVector(x,y,run)
	local banana={(x+((run and mcontroller.facingDirection()) or 0))*2,y*2}
	banana[1]=banana[1]+((math.random()-0.5)*0.35)
	banana[2]=banana[2]+((math.random()-0.5)*0.35)
	return banana
end

function update(args)
	self.mouthPosition = vec2.add(mcontroller.position(), {mcontroller.facingDirection(),(args.moves["down"] and -0.7) or 0.15})

	self.firetimer = math.max(0, (self.firetimer or 0) - args.dt)
	local upDown=((args.moves["down"] and -1) or 0) + ((args.moves["up"] and 1) or 0)
	local leftRight=((args.moves["left"] and -1) or 0) + ((args.moves["right"] and 1) or 0)
	if args.moves["special1"] and status.overConsumeResource("energy", 0.001) then
		if checkFood() > foodThreshold then
			status.addEphemeralEffects{{effect = "foodcostfiretech", duration = 0.001}}
		else
			status.overConsumeResource("energy", 0.25)
		end

		if self.firetimer == 0 then
			self.firetimer = 0.1 --+ (totalVal / 50)
			activeFlight(aimVector(leftRight,upDown,args.moves["run"]))
		end
	
	else
		animator.stopAllSounds("activate")
	end
end