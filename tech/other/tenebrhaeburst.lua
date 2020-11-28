require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  --self.species = world.entitySpecies(entity.id())
  self.firetimer = 0
  self.rechargeDirectives = "?fade=CC1122FF=0.25"
  self.rechargeDirectivesNil = nil
  self.rechargeEffectTime = 0.1
  self.rechargeEffectTimer = 0
  self.flashCooldownTimer = 0
  self.halted = 0
  --checkFood()
end

--[[function uninit()
end]]

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

--[[function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end]]

--[[function undergroundCheck()
	return world.underground(mcontroller.position())
end]]

function checkFood()
	local foodValue=15
	if status.isResource("food") then
		foodValue = status.resource("food")
	end
	return foodValue
end

--[[function damageConfig()
	--local daytime = daytimeCheck()
	--local underground = undergroundCheck()
  --foodVal =
  --energyVal =
  totalVal =
end]]

function activeFlight()
    --damageConfig()
    local damageConfig = {
      power = ((checkFood() /60) + (status.resource("energy")/150) + (27 - (getLight()/2))),
      knockback = 50
    }
    animator.playSound("activate",3)
    animator.playSound("recharge")
    world.spawnProjectile("fumechbladeshadowswoosh", mcontroller.position(), entity.id(), aimVector(), false, damageConfig)
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

--[[function chargeUp()

end]]

function update(args)
        self.firetimer = math.max(0, self.firetimer - args.dt)
        --checkFood()

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
		if checkFood() > 15 then
		    status.addEphemeralEffects{{effect = "foodcostshadow", duration = 0.5}}
		else
		    status.overConsumeResource("energy", 40)
		end
		self.firetimer = 3
		activeFlight()
		self.dashCooldownTimer = 3
		self.flashCooldownTimer = 3
		self.halted = 0
	else
  	        animator.stopAllSounds("activate")
	end
end

function idle()

end