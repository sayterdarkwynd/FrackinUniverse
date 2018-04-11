
texts = {
	"^green;SENTIENT LIFEFORM DETECTED. RELEASING TIME CAPSULE.^reset;",
	"^green;ID POSITIVE: NEW SPECIES RECOGNIZED. RELEASING TIME CAPSULE.^reset;",
	"^green;PROTOCOL 2 ACTIVATED.^reset;"
}

function init()
	message.setHandler('scanInteraction', scanInteraction)
	
	if storage.state == nil then
		output(config.getParameter("defaultSwitchState", false))
	else
		output(storage.state)
	end
	
	if storage.triggered == nil then
		storage.triggered = false
	end
end

function onInteraction()
	object.setInteractive(false)
	output(not storage.state)
end

function scanInteraction()
	object.say(texts[math.random(1, #texts)])
	object.setInteractive(true)

      if not self.scanned then
	      local pool = config.getParameter("treasure.pool")
	      local level = config.getParameter("treasure.level")
	      local seed = config.getParameter("treasure.seed")
	      local treasure = root.createTreasure(pool, level, seed)
	      world.spawnTreasure(object.position(), pool, level, seed) 
	      world.spawnTreasure(object.position(), "fuprecursorResources", 1, 1)
	      self.scanned = 1
      	      animator.burstParticleEmitter("teleportOut")
      	      animator.playSound("deathPuff")
      end      

end

function output(state)
	storage.state = state
	if state then
		object.setAllOutputNodes(true)
	else
		object.setAllOutputNodes(false)
	end
end
