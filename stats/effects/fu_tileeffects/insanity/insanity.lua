function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.0005
  self.tickTime = 5.0
  self.tickTimer = self.tickTime
  activateVisualEffects()
  self.timers = {} 
  _x = config.getParameter("defenseModifier", 0)
  baseValue = config.getParameter("defenseModifier",0)*(status.stat("protection"))
  effect.addStatModifierGroup({{stat = "protection", amount = baseValue }})
end


function activateVisualEffects()
  
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end
function activateVisualEffects2()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext2", statusTextRegion)
  animator.burstParticleEmitter("statustext2")
end

function update(dt)

  	if ( status.stat("shadowResistance",0)  >= 0.60 ) and ( status.stat("cosmicResistance",0)  >= 0.60 ) then
	  effect.expire() 
	end  
	
	if world.entityType(entity.id()) == "player" then
		status.addEphemeralEffect( "insanityblurstat")	
	end	

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        effect.addStatModifierGroup({{stat = "protection", amount = baseValue }}),
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "poison",
        sourceEntityId = entity.id(),
        activateVisualEffects2()
      })
  end
end


function uninit()
   
end