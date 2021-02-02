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
function frackinship.CompareRaces(raceA, raceB)
	local a = fsComparableName(raceA)
	local b = fsComparableName(raceB)
	return a < b
end

function frackinship.ComparableName(name)
	return name:gsub('%^#?%w+;', '') -- removes the color encoding from names, e.g. ^blue;Madness^reset; -> Madness
		:gsub('ū', 'u')
		:upper()
end