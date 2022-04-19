function activate()
	item.consume(1)
	world.spawnMonster('punchy', mcontroller.position(), { persistent = true })
end
