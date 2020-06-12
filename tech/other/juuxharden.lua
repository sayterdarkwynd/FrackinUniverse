require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  --self.species = world.entitySpecies(entity.id())
  self.firetimer = 0
end

--[[function uninit()
end]]

--[[function damageConfig()
  energyVal = 
  defenseVal =  
  totalVal = 
end]]

function activeFlight(direction)
    --damageConfig()
    --local damageConfig = 
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)
    world.spawnProjectile("plasmafistrocketpharitu", self.mouthPosition, entity.id(), direction, false, { power = (((status.resource("energy")/150) + (status.stat("protection") /250))), damageSourceKind = "cosmic" })
end
--[[function activeFlight2()
    --damageConfig()
    --local damageConfig = 
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)
    world.spawnProjectile("plasmafistrocketpharitu", self.mouthPosition, entity.id(), , false, { power = (((status.resource("energy")/150) + (status.stat("protection") /250))), damageSourceKind = "cosmic" })
end]]
--[[
function activeFlight3()
    --damageConfig()
    --local damageConfig = 
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)
    world.spawnProjectile("plasmafistrocketpharitu", self.mouthPosition, entity.id(), , false, { power = (((status.resource("energy")/150) + (status.stat("protection") /250))), damageSourceKind = "cosmic" })
end]]

function aimVector()
  local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end


function update(args)
	if mcontroller.facingDirection() == 1 then -- what direction are we facing?
		if args.moves["down"] then -- are we crouching?
			self.mouthPosition = vec2.add(mcontroller.position(), {1,-0.7})  
		else
			self.mouthPosition = vec2.add(mcontroller.position(), {1,0.15}) 
		end

	else
		if args.moves["down"] then -- are we crouching?
			self.mouthPosition = vec2.add(mcontroller.position(), {-1,-0.7})  
		else
			self.mouthPosition = vec2.add(mcontroller.position(), {-1,0.15}) 
		end          
	end

	self.firetimer = math.max(0, self.firetimer - args.dt)

	if args.moves["special1"] and not args.moves["down"] and not args.moves["up"] and status.overConsumeResource("energy", 0.001) then 
		if self.firetimer == 0 then
			status.overConsumeResource("energy", 2)

			self.firetimer = 0.05
			activeFlight(aimVector())
		end

	else
		animator.stopAllSounds("activate")	
	end
	if args.moves["down"] and args.moves["special1"] and status.overConsumeResource("energy", 0.001) then 
		if self.firetimer == 0 then
			status.overConsumeResource("energy", 2)

			self.firetimer = 0.05
			activeFlight({0,-2})
		end

	else
		animator.stopAllSounds("activate")	
	end
	if args.moves["up"] and args.moves["special1"] and status.overConsumeResource("energy", 0.001) then 
		if self.firetimer == 0 then
			status.overConsumeResource("energy", 2)

			self.firetimer = 0.05
			activeFlight({0,2})
		end

	else
	animator.stopAllSounds("activate")	
	end	
end
--[[
function idle()
end]]