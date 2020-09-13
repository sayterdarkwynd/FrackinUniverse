require "/scripts/vec2.lua"

function init()
	message.setHandler("createShip", createShip)
end

function update()
	if self.bootupCounter then
		if self.bootupCounter <= 0 then
			world.setProperty("fu_byos", true)
			self.bootupCounter = nil
		else
			self.bootupCounter = self.bootupCounter - 1
		end
	end
end

function createShip(_, _, ship, racialiseRace, replaceMode)
	sb.logInfo(tostring(ship))
	replaceMode = replaceMode or {dungeon = "fu_byosblankquarter", size = {512, 512}}
	if ship then
		world.placeDungeon(replaceMode.dungeon, getReplaceModePosition(replaceMode.size))
		world.placeDungeon(ship.ship, vec2.add({1024, 1024}, ship.offset or {-6, 12}))
		self.bootupCounter = config.getParameter("bootupCounter" or 0) --maybe change later
	end
end

function getReplaceModePosition(size)
	local position = {1024, 1024}
	local halfSize = vec2.div(size, 2)
	position[1] = position[1] - halfSize[1]
	position[2] = position[2] + halfSize[2] + 1
	
	return position
end