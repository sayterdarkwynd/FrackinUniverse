
texts = {
	"Oh yeah baby one more time",
	"Hhhng, oh yeah thats the spot",
	"Again, AGAIN!",
	"Scan me like one of your travel suit cases",
	"Scan every inch of me baby",
	"Oh yeah thats so hot",
	"Like what you're seeing? ;)",
	"Can I scan whats under your clothing? ;)",
	"Don't just scan me, TAKE ME! TAKE ME NOW!"
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
	      world.spawnTreasure(object.position(), pool, level, seed)
	      self.scanned = 1
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
