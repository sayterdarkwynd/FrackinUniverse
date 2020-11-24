require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  --self.species = world.entitySpecies(entity.id())
  self.firetimer = 0
  self.facingDirection = 1

  checkFood()
end

--[[function uninit()

end]]

function checkFood()
	if status.isResource("food") then
		return status.resource("food")		
	else
		return 15
	end
end

--[[function damageConfig()
  foodVal = self.foodValue /60
  energyVal = status.resource("energy")/150
  defenseVal =  status.stat("protection") /250
  totalVal = foodVal + energyVal + defenseVal
end]]

function activeFlight()
    --damageConfig()
    --local damageConfig = { power = totalVal, damageSourceKind = "fire", speed = 12 }
    --sb.logInfo("power value from food, energy and protection = "..damageConfig.power)
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)

    world.spawnProjectile("elduukharflamethrower",self.mouthPosition, entity.id(), aimVector(), false, { power = ((checkFood() /60) + (status.resource("energy")/150) + (status.stat("protection") /250)), damageSourceKind = "fire", speed = 12 })
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end


function update(args)
        --checkFood()

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
	if args.moves["special1"] and status.overConsumeResource("energy", 0.001) then
	  self.facingDirection = world.distance(aimVector(), mcontroller.position())[1] > 0 and 1 or -1  --what direction are we facing
		if checkFood() > 15 then
		    status.addEphemeralEffects{{effect = "foodcostfire", duration = 0.02}}
		else
		    status.overConsumeResource("energy", 0.6)
		end	
	
	      if self.firetimer == 0 then
		self.firetimer = 0.1
		activeFlight()
	      end
	    	
	else
  	        animator.stopAllSounds("activate")	
	end
end

--[[function idle()

end]]