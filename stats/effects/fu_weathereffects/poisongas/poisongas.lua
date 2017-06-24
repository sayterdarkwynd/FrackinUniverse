require "/scripts/unifiedGravMod.lua"

function init()
if (status.stat("poisonResistance",0)  >= 1.0) or status.statPositive("poisonStatusImmunity") or status.statPositive("gasImmunity") then
  effect.expire()
end
	self.gravityMod = config.getParameter("gravityMod",20.0)
	self.gravityNormalize = config.getParameter("gravityNorm",false)
	self.gravityBaseMod = config.getParameter("gravityBaseMod",0.0)
	self.movementParams = mcontroller.baseParameters()
	unifiedGravMod.init()
	
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
  self.liquidMovementParameter = {
    groundForce = 70,
    airForce = 20,
    airFriction = 0.3,
    liquidForce = 70,
    liquidFriction = 0.35,
    liquidImpedance = 0.1,
    liquidBuoyancy = 0.25,
    minimumLiquidPercentage = 0.1,
    liquidJumpProfile = {
      jumpSpeed = 70.0,
      jumpControlForce = 610.0,
      jumpInitialPercentage = 0.45,
      jumpHoldTime = 0.01,
      multiJump = false,
      reJumpDelay = 0.5,
      autoJump = false,
      collisionCancelled = false
    }
  }  
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
  	if ( status.stat("poisonResistance",0)  >= 0.5 ) then
	  effect.expire() 
	end  
      biomeTimer = biomeTimer - dt
  unifiedGravMod.update(dt)
  mcontroller.controlParameters(self.liquidMovementParameter)      
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