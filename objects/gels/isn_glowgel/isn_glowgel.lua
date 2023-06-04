function init()
	self.placed = true
end

function update(dt)
	if not self.placed then return end

	local gelPosi = getSurroundingTileList()
	for _, value in pairs(gelPosi) do
		applyGel(value)
	end

	entity.smash()
end

function getSurroundingTileList()
	local tileList = {}
	table.insert(tileList,{entity.position()[1] - 1, entity.position()[2]})
	table.insert(tileList,{entity.position()[1] + 1, entity.position()[2]})
	table.insert(tileList,{entity.position()[1], entity.position()[2] - 1})
	table.insert(tileList,{entity.position()[1], entity.position()[2] + 1})
	table.insert(tileList,{entity.position()[1] + 1, entity.position()[2] + 1})
	table.insert(tileList,{entity.position()[1] + 1, entity.position()[2] - 1})
	table.insert(tileList,{entity.position()[1] - 1, entity.position()[2] + 1})
	table.insert(tileList,{entity.position()[1] - 1, entity.position()[2] - 1})
	return tileList
end

function applyGel(gel_position)
	if not world.tileIsOccupied(gel_position,true,false) then return false end
	world.placeMod(gel_position,"foreground",config.getParameter("modToPlace"),nil,false)
end
