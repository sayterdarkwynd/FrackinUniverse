
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
	script.setUpdateDelta(60)
end

function onInteraction()
	object.setInteractive(false)
	output(not storage.state)
end

function scanInteraction()
	if not storage.scanned then
		object.say(texts[math.random(1, #texts)])
		object.setInteractive(true)
		storage.scanned=true
		storage.scanTimer=3.0
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

function update(dt)
	if not storage.scanned or not storage.scanTimer then return end
	if storage.scanTimer > 0 then
		storage.scanTimer=storage.scanTimer-dt
	else
		local pool = config.getParameter("treasure.pool")
		local level = config.getParameter("treasure.level")
		local seed = config.getParameter("treasure.seed")
		local inactiveVariant = config.getParameter("inactiveVariant")
		world.spawnTreasure(object.position(), pool, level, seed)
		world.spawnTreasure(object.position(), "fuprecursorResources", 1, 1)
		animator.burstParticleEmitter("teleportOut")
		animator.playSound("deathPuff")
		if inactiveVariant then
			world.spawnItem({name=inactiveVariant,amount=1,{}},entity.position())
		end
		object.smash()
	end
end
