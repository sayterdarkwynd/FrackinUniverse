require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

function init()
	if status.statPositive("specialStatusImmunity") then
		effect.expire()
		return
	end
	eType=world.entityType(entity.id())
	if not eType then return end
	if eType=="monster" then
		effect.setParentDirectives(config.getParameter("directives", ""))
		effect.addStatModifierGroup({{stat = "deathbombDud", amount = 1}})
		isMonster=true
	end
	if not blocker then blocker=config.getParameter("blocker","warpedcapture") end
	initDone=true
end


function update(dt)
	if not initDone then init() end
	if isMonster then
		hit()
	end
end

function hit()
	if self.hit or status.statPositive(blocker)then return end
	if isMonster then
		-- If a monster doesn't implement pet.attemptCapture or its response is nil
		-- then it isn't caught.
		podData=world.callScriptedEntity(entity.id(), "capturable.attemptCapture", entity.id())

		if podData then
			if not blocker then blocker=config.getParameter("blocker","warpedcapture") end
			spawnFilledPod(podData)
			self.hit=true
			status.addPersistentEffect(blocker,{stat=blocker,amount=1})
			world.callScriptedEntity(entity.id(),"monster.setDropPool",nil)
			status.setResourcePercentage("health",0)
		end
	end
end

function spawnFilledPod(pet)
  local pod = createFilledPod(pet)
  --world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
  world.spawnItem(pod, mcontroller.position())
end
