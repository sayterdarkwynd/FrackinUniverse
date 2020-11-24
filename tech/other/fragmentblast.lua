require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  --self.species = world.entitySpecies(entity.id())
  self.firetimer = 0
  checkFood()
end

function uninit()

end

function checkFood()
	if status.isResource("food") then
		self.foodValue = status.resource("food")
	else
		self.foodValue = 15
	end
end

function damageConfig()
  foodVal = self.foodValue /20
  energyVal = status.resource("energy")/50
  defenseVal =  status.stat("protection") /120
  totalVal = 2 + (foodVal + energyVal + defenseVal) * self.bonusDamage -- add tech bonus damage from armor etc with self.bonusDamage
end

function activeFlight()
    damageConfig()
    local damageConfig = { power = totalVal, damageSourceKind = "fire" }
    animator.playSound("activate",3)
    animator.playSound("recharge")
    animator.setSoundVolume("activate", 0.5,0)
    animator.setSoundVolume("recharge", 0.375,0)
    world.spawnProjectile("fuenergyshardplayertech", self.mouthPosition, entity.id(), {math.random(-360,360),math.random(-360,360),math.random(-360,360)}, false, damageConfig)
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end


function applyTechBonus()
  self.bonusDamage = 1 + status.stat("bombtechBonus") -- apply bonus from certain items and armor
end

function update(args)
  applyTechBonus()
        checkFood()

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
		if self.foodValue > 15 then
		    status.addEphemeralEffects{{effect = "foodcostfiretech", duration = 0.001}}
		else
		    status.overConsumeResource("energy", 0.25)
		end

	      if self.firetimer == 0 then
	        damageConfig()
		self.firetimer = 0.1 + (totalVal / 50)
		activeFlight()
	      end
	    
	else
  	        animator.stopAllSounds("activate")
	end
end

function idle()

end