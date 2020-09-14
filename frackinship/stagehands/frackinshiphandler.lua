require "/scripts/vec2.lua"
require "/interface/objectcrafting/fu_racializer/fu_racializer_gui.lua"

function init()
	message.setHandler("createShip", createShip)
	self.shipDungeonId = config.getParameter("shipDungeonId", 10101)
end

function update()
	if self.placingShip  and world.dungeonId(entity.position()) == self.shipDungeonId then
		world.setProperty("fu_byos", true)
		racialiseShip()
		self.placingShip = false
	end
end

function createShip(_, _, ship, playerRace, replaceMode)
	self.playerRace = playerRace or "apex"
	self.racialiseRace = ship.racialiserOverride or self.playerRace
	replaceMode = replaceMode or {dungeon = "fu_byosblankquarter", size = {512, 512}}
	if ship then
		world.placeDungeon(replaceMode.dungeon, getReplaceModePosition(replaceMode.size))
		world.placeDungeon(ship.ship, vec2.add({1024, 1024}, ship.offset or {-6, 12}), self.shipDungeonId)
		self.placingShip = true
	end
end

function getReplaceModePosition(size)
	local position = {1024, 1024}
	local halfSize = vec2.div(size, 2)
	position[1] = position[1] - halfSize[1]
	position[2] = position[2] + halfSize[2] + 1
	
	return position
end

function racialiseShip()
	-- put treasure generating stuff here
	local objects = world.objectQuery(entity.position(), config.getParameter("racialiseRadius", 128))
	for _, object in ipairs (objects) do
		local racialiserType = world.getObjectParameter(object, "racialiserType")
		if racialiserType then
			local newItem = root.itemConfig(self.racialiseRace .. racialiserType)	--add race table override support later
			if newItem then
				sb.logInfo(self.racialiseRace .. racialiserType .. " exists")
			else
				sb.logInfo(self.racialiseRace .. racialiserType .. " does not exist")
			end
		end
		-- put treasure placing stuff here
	end
end