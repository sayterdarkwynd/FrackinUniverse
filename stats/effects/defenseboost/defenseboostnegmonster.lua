function init()
  animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
  animator.setParticleEmitterActive("snow", true)
  effect.setParentDirectives("fade=6f6f6f=0.55")
  if (world.entityType(entity.id()) == "player") or (world.entityType(entity.id()) == "npc") then
	   effect.addStatModifierGroup({
	     {stat = "protection", baseMultiplier = status.stat("protection") * config.getParameter("defenseAmount", 0)},
	     {stat = "physicalResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "fireResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "iceResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "poisonResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "electricResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "radioactiveResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "shadowResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "cosmicResistance", amount = config.getParameter("defenseAmount2", 0)},
	     {stat = "healingStatusImmunity", amount = 1 }
	   })
	   makeAlert()	   
   end
   script.setUpdateDelta(0)
end

function makeAlert()
	  local statusTextRegion = { 0, 1, 0, 1 }
	  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	  animator.burstParticleEmitter("statustext")  
end


function update(dt)

end

function uninit()
  
end