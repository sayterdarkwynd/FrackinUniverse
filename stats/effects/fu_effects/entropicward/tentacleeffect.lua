function init()
	if world.entityType(entity.id()) == "player" then
	  animator.setAnimationState("aura", "on")
	  self.valuea = status.stat("protection") * 0.25
	  effect.addStatModifierGroup({
	    {stat = "protection", amount = self.valuea }
	    }) 
	else
	  status.addEphemeralEffect("l6doomed", 6, entity.id())
	  status.addEphemeralEffect("blacktarslow", 6, entity.id())
          status.addEphemeralEffect("insanity", 6, entity.id())
          animator.setAnimationState("aura", "on")
          effect.addStatModifierGroup({{stat = "physicalResistance", amount = config.getParameter("resistanceAmount", 0)}})          
	end
	
  self.randVal = math.random(1,12) 
  self.randVal2 = math.random(1,100)
  if (self.randVal2 >= 75) then
    world.spawnItem("fumadnessresource",entity.position(),self.randVal)	
  end
end

function update(dt)

end

function uninit()
  if not world.entityType(entity.id()) == "player" then
    status.removeEphemeralEffect("blacktarslow")
    status.removeEphemeralEffect("insanity")
    status.removeEphemeralEffect("l6doomed")
  end
end
