require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

function init()
	if world.isMonster(entity.id()) then
		effect.setParentDirectives(config.getParameter("directives", ""))
		effect.addStatModifierGroup({{stat = "deathbombDud", amount = 1}})
		isMonster=true
	end
end


function update(dt)
	if isMonster then
		hit()
	end
end

function hit()
	if self.hit or (status.stat("warpedcaptureblocker") > 0)then return end
	if isMonster then
		-- If a monster doesn't implement pet.attemptCapture or its response is nil
		-- then it isn't caught.
		podData=world.callScriptedEntity(entity.id(), "capturable.attemptCapture", entity.id())
		
		if podData then
			spawnFilledPod(podData)
			self.hit=true
			status.addPersistentEffect("warpedcaptureblocker",{stat="warpedcaptureblocker",amount=1})
			world.callScriptedEntity(entity.id(),"monster.setDropPool",nil)
			status.setResourcePercentage("health",0)
		end
	end
end

function spawnFilledPod(pet)
  local pod = createFilledPod(pet)
  world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
end
