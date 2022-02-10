require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function activeFlight()
	local aimPos=tech.aimPosition()
	local direction=vec2.norm(world.distance(aimPos,entity.position()))
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)
    world.spawnProjectile("plasmafistrocketpharitu",self.mouthPosition,entity.id(),direction,true,{power=((status.resource("energy")/150)+(status.stat("protection")/250)),damageSourceKind="cosmic"})
end

function update(args)
	self.firetimer = math.max(0, (self.firetimer or 0) - args.dt)
	if args.moves["special1"] and not status.resourceLocked("energy") then--status.overConsumeResource("energy", 0.001) then
		if self.firetimer == 0 then
			status.overConsumeResource("energy", 2)

			self.firetimer = 0.05
			self.mouthPosition = vec2.add(mcontroller.position(), {mcontroller.facingDirection(),(args.moves["down"] and -0.7) or 0.15})
			activeFlight()
		end
	else
		animator.stopAllSounds("activate")
	end
end