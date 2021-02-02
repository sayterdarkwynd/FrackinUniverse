frackinship = {}

function frackinship.getRaceList()
	local raceList = {}
	local racesLower = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	local raceShips = root.assetJson("/universe_server.config").speciesShips
	local racesLowerTable = {}
	for _, race in ipairs (racesLower) do
		racesLowerTable[race] = true
	end
	for race, _ in pairs (raceShips) do
		if racesLowerTable[string.lower(race)] then
			table.insert(raceList, race)
		end
	end
	table.sort(raceList, frackinship.compareRaces)
	return raceList
end

-- Copied from terminal code
function frackinship.compareRaces(raceA, raceB)
	local a = frackinship.comparableName(raceA)
	local b = frackinship.comparableName(raceB)
	return a < b
end

function frackinship.comparableName(name)
	return name:gsub('%^#?%w+;', '') -- removes the color encoding from names, e.g. ^blue;Madness^reset; -> Madness
		:gsub('ū', 'u')
		:upper()
end