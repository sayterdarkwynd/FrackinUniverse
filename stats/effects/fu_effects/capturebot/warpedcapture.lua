require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

function init()
  effect.setParentDirectives(config.getParameter("directives", ""))
end


function update(dt)
  hit()
end

function hit()
	if self.hit then return end
	if world.isMonster(entity.id()) then
		-- If a monster doesn't implement pet.attemptCapture or its response is nil
		-- then it isn't caught.
		podData=world.callScriptedEntity(entity.id(), "capturable.attemptCapture", entity.id())
		
		if podData then
			effect.addStatModifierGroup({{stat = "deathbombDud", amount = 1}})
			spawnFilledPod(podData)
			self.hit=true
			world.callScriptedEntity(entity.id(),"monster.setDropPool",nil)
			status.setResourcePercentage("health",0)
		end
	end
end

function spawnFilledPod(pet)
  local pod = createFilledPod(pet)
  world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
end
