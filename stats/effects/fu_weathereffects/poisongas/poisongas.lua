function init()
if (status.stat("poisonResistance",0)  >= 1.0) or status.statPositive("gasImmunity") then
  effect.expire()
end

  script.setUpdateDelta(5)

  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true)
  
  --config --
  decreasePower = config.getParameter("decreasePower",0)
  biomeTimer = 5
  local bounds = mcontroller.boundBox()
  effect.setParentDirectives("fade=ffea00=0.027")
  baseValue = config.getParameter("biomeDmgPerTick")
  activateVisualEffects()
end


function activateVisualEffects()
  effect.setParentDirectives("fade=306630=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end


function makeAlert()
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          entity.id(),
          directionTo,
          false,
          {
            power = 0,
            damageTeam = sourceDamageTeam
          }
        )
        animator.playSound("bolt")
end


  
function update(dt)
      biomeTimer = biomeTimer - dt
      if biomeTimer <= 0 and status.stat("powerMultiplier") >= 1 then
        effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue* (-1) }})
        effect.addStatModifierGroup({{stat = "maxEnergy", amount = baseValue* (-1) }})
	biomeTimer = 5	
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = 7,
          damageSourceKind = "poison",
          sourceEntityId = entity.id(),  
          biomeTimer = 2	
          })	
	makeAlert()
	activateVisualEffects()
      end	

       

end

function uninit()

end