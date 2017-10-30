--[[ not doing honey centrifuges & extractors just yet
require "/objects/bees/centrifuge.lua"
beeCentrifuge = deciding() -- input: {outputs}

require "objects/bees/honeymap.lua"
...
NOTE: for the LEGEND
		each station functions differently, you will NOT get same quantities with different stations even if the color is identical.
		colors are just general indicators.
		colors vary from green to variants of yellows to variants of reds
		green mean you'll get lots, yellows less, reds even less

]]


centrifuge = {}
centrifuge2 = {}
blastFurnace = {}
arcSmelter = {}

processObjects = {}
recognisedObjects = {}
materials = {}
materialsSorted = {}
materialsMissing = {}

MATERIALS = "materialList.materials"
RECIPES = "recipeList.recipes"
BLANK = "recipeList.empty"
NOSTATIONS = "recipeList.nostations"

update = nil
uninit = nil

--initialised = false

nearbystationsfound = {}

function init()
	--if initialised then
	--	sb.logWarn("Crafting Info Display skipping init") -- this is actually NEVER executed, leaving it here for now
	--	return
	--end
	--initialised = true
	--sb.logWarn("Crafting Info Display init")

	extractionLab = root.assetJson("/objects/generic/extractionlab_recipes.config") -- {inputs}, {outputs}
	xenoLab = root.assetJson('/objects/generic/xenostation_recipes.config') -- {inputs}, {outputs}
	centrifugeLab = root.assetJson("/objects/generic/centrifuge_recipes.config")  -- it's more complicated than the above two & also includes sifter
	liquidLab = root.assetJson("/objects/power/fu_liquidmixer/fu_liquidmixer_recipes.config")

	self.matfilter = getFilter()
	-- script.setUpdateDelta(1) -- is there even a reason for this ? commented out
	script.setUpdateDelta(0) -- imported from update() function


	local getLists = function(name)
		local conf = root.itemConfig({name = name})
		return {
			config = {
				shortdescription = conf.config.shortdescription,
				inventoryIcon = rescale(canonicalise(conf.config.inventoryIcon, conf.directory), 16, 16)
			},
			main = conf.config.inputsToOutputs,
			extra = conf.config.bonusOutputs
		} -- input: output, input: {outputs}
	end

	-- centrifuge = getLists("centrifuge")
	-- centrifuge2 = getLists("centrifuge2")
	blastFurnace = getLists("fu_blastfurnace")
	arcSmelter = getLists("isn_arcsmelter")

	-- relocalized  to before getNearbyStations execution
	recognisedObjects = { -- we need this one for the ordering of display results
		-- in order of processing
		"quantumextractor",
		"extractionlabadv",
		"extractionlab",
		"xenostationadvnew",
		"xenostation",
		"centrifuge2",
		"centrifuge",
		"industrialcentrifuge",
		"ironcentrifuge",
		"woodencentrifuge",
		"isn_powdersifter",
		"fu_woodensifter",
		"isn_arcsmelter",
		"fu_blastfurnace",
		"fu_liquidmixer"
	}
	recognisedObjectsKey = { -- true is a dummy value, this table was added as a convenience to avoid looping through
		["quantumextractor"] = true,
		["extractionlabadv"] = true,
		["extractionlab"] = true,
		["xenostationadvnew"] = true,
		["xenostation"] = true,
		["centrifuge2"] = true,
		["centrifuge"] = true,
		["industrialcentrifuge"] = true,
		["ironcentrifuge"] = true,
		["woodencentrifuge"] = true,
		["isn_powdersifter"] = true,
		["fu_woodensifter"] = true,
		["isn_arcsmelter"] = true,
		["fu_blastfurnace"] = true,
		["fu_liquidmixer"] = true
	}
	nearbystationsfound = getNearbyStations() -- this should limit the searching for stations nearby everytime the lists are updated
	-- however it also means if a new station is added, you need to exit & reenter the lab directory//craftinfo for it to show

	local found = nearbystationsfound
	-- this will make processObjects only contain information about found nearbystations
	if found["quantumextractor"] then
		processObjects["quantumextractor"]		= { mats = getExtractionMats, spew = doExtraction, data = extractionLab } end
	if found["extractionlabadv"] then
		processObjects["extractionlabadv"]		= { mats = getExtractionMats, spew = doExtraction, data = extractionLab } end
	if found["extractionlab"] then
		processObjects["extractionlab"]			= { mats = getExtractionMats, spew = doExtraction, data = extractionLab } end
	if found["xenostationadvnew"] then
		processObjects["xenostationadvnew"]		= { mats = getExtractionMats, spew = doExtraction, data = xenoLab } end
	if found["xenostation"] then
		processObjects["xenostation"]			= { mats = getExtractionMats, spew = doExtraction, data = xenoLab } end
	if found["centrifuge2"] then
		processObjects["centrifuge2"]			= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["centrifuge"] then
		processObjects["centrifuge"]			= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["industrialcentrifuge"] then
		processObjects["industrialcentrifuge"]	= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["ironcentrifuge"] then
		processObjects["ironcentrifuge"]		= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["woodencentrifuge"] then
		processObjects["woodencentrifuge"]		= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["isn_powdersifter"] then
		processObjects["isn_powdersifter"]		= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["fu_woodensifter"] then
		processObjects["fu_woodensifter"]		= { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab } end
	if found["isn_arcsmelter"] then
		processObjects["isn_arcsmelter"]		= { mats = getSepSmeltMats, spew = doSepOrSmelt, data = arcSmelter } end
	if found["fu_blastfurnace"] then
		processObjects["fu_blastfurnace"]		= { mats = getSepSmeltMats, spew = doSepOrSmelt, data = blastFurnace } end
	if found["fu_liquidmixer"] then
		processObjects["fu_liquidmixer"]		= { mats = getExtractionMats, spew = doLiquidInteraction, data = liquidLab } end

--[[	processObjects = {
		extractionlab         = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		extractionlabadv      = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		quantumextractor      = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		xenostation           = { mats = getExtractionMats, spew = doExtraction, data = xenoLab },
		xenostationadvnew     = { mats = getExtractionMats, spew = doExtraction, data = xenoLab },
		centrifuge            = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		centrifuge2           = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		industrialcentrifuge  = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		ironcentrifuge        = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		woodencentrifuge      = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		isn_powdersifter      = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		fu_woodensifter       = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		fu_blastfurnace       = { mats = getSepSmeltMats, spew = doSepOrSmelt, data = blastFurnace },
		isn_arcsmelter        = { mats = getSepSmeltMats, spew = doSepOrSmelt, data = arcSmelter },
		fu_liquidmixer        = { mats = getExtractionMats, spew = doLiquidInteraction, data = liquidLab }
	}	]]--

	for station, info in pairs(processObjects) do
		if info.mats then
			info.mats(info.data, station)
		end
	end
	table.sort(materialsSorted, function(a, b)
		if a.name < b.name then return true end
		if a.name > b.name then return false end
		return a.id < b.id
	end)

	populateMaterialsList() -- importing what's in the update function
end

-- function update()
	-- script.setUpdateDelta(0)
	-- populateMaterialsList()
	-- sb.logWarn("Crafting Info Display Passing Through Update")
-- end

function getFilter()
	return widget.getText('tbFind'):gsub('^ +', ''):gsub(' +$', ''):gsub('  +', ' '):lower()
end

-- function onInteraction(args)
-- end

function tbFind()
	local newfilter = getFilter()
	if newfilter == '' then newfilter = nil end
	if newfilter ~= self.matfilter then
		-- trim, collapse spaces, lower case
		self.matfilter = newfilter
		populateMaterialsList()
	end
end

function doFindInput()
	doFind(true)
end

function doFindOutput()
	doFind(false)
end

function doFind(isInput)
	local lookup = widget.getListSelected(MATERIALS)
	if not lookup then return end
	lookup = widget.getData(string.format("%s.%s", MATERIALS, lookup))
	populateResultsList(isInput and lookup, not isInput and lookup)
end

-- Materials list

function registerMaterial(mat, station)
	if materialsMissing[mat] then return end
	if not materials[mat] then
		-- this will probably spam the log file a bit; not much can be done about it
		-- Skipping all wild* except wildvines
		if string.sub(mat,1,4) == 'wild' and mat ~= 'wildvines' then
			materialsMissing[mat] = true
			return
		end
		-- saplings are special-cased
		local sapling = mat == 'sapling'
		if not sapling and not root.itemConfig(mat) then
			materialsMissing[mat] = true
			-- commented out the creation of warnings cause recipes exist for mods not always installed
			-- sb.logInfo("Crafting Info Display found non-existent item '%s'", mat)
			return
		end
		local data = root.itemConfig({ name = mat, data = { stemName = 'pineytree' } })
		if sapling then
			-- workaround: show something with trunk and leaf info
			data.config.inventoryIcon = '/interface/scripted/fu_craftinfo/sapling.png'
		elseif type(data.config.inventoryIcon) == 'table' then
			-- handle multi-icon items by just using the first icon (broken, I know)
			data.config.inventoryIcon = data.config.inventoryIcon[1].image
		end
		materials[mat] = { stations = {}, id = mat, name = data.config.shortdescription, icon = rescale(canonicalise(data.config.inventoryIcon, data.directory), 16, 16) }
		table.insert(materialsSorted, materials[mat])
	end
	materials[mat].stations[station] = true
end

function populateMaterialsList()
	widget.clearListItems(MATERIALS)
	-- sb.logWarn("Crafting Info Display - is going through populateMaterialsList")
	local listed = false
	local found = nearbystationsfound -- getNearbyStations()

	if found then
		local filter = self.matfilter

		for _, mat in ipairs(materialsSorted) do
			for station, _ in pairs(mat.stations) do
				if found[station] and (not filter or mat.name:lower():find(filter, 1, true)) then
					local path = string.format("%s.%s", MATERIALS, widget.addListItem(MATERIALS))
					widget.setText(path .. ".text", mat.name)
					widget.setImage(path .. ".icon", mat.icon)
					widget.setData(path, mat.id)
					listed = true
					break
				end
			end
		end
	end

	widget.setButtonEnabled('btnFindInput', listed)
	widget.setButtonEnabled('btnFindOutput', listed)
end

-- Results list

function populateResultsList(itemIn, itemOut)
	widget.clearListItems(RECIPES)
	widget.setVisible(BLANK, false)
	widget.setVisible(NOSTATIONS, false)
	-- sb.logWarn("Crafting Info Display - is populating the result list"  )
	if not itemIn and not itemOut then
		widget.setVisible(BLANK, true)
		return
	end

	local found = nearbystationsfound -- getNearbyStations()
	if not found then
		widget.setVisible(NOSTATIONS, true)
		return
	end

	local list = {}
	addHeadingItem(materials[itemIn or itemOut], list)

	for _, station in pairs(recognisedObjects) do
		if found[station] then
			local info = processObjects[station]
			info.spew(list, info.data, itemIn, itemOut, station)
		end
	end

	-- hack: resize widgets in the list to account for possible text wrapping
	-- this will IGNORE some size + spacing settings!

	local schema = config.getParameter('gui.recipeList.children.recipes.schema')
	local spacing = schema.spacing[2]
	local y = spacing * 2 -- convenience for later subtraction
	for _, item in ipairs(list) do
		local parentSize = widget.getSize(item)
		local parentPos = widget.getPosition(item)
		local textHeight = widget.getSize(item .. '.text')[2]
		local height = math.max(widget.getSize(item .. '.icon')[2], textHeight) + 2
		y = y + height + spacing
		widget.setSize(item, { parentSize[1], height })
		widget.setPosition(item .. '.text', { widget.getPosition(item .. '.text')[1], (height - textHeight) / 2 })
		widget.setPosition(item .. '.direction', { widget.getPosition(item .. '.direction')[1], height - 1 })
	end
	local tableSize = widget.getSize(RECIPES)
	widget.setSize(RECIPES, { widget.getSize(RECIPES)[1], y })
	for _, item in ipairs(list) do
		local size = widget.getSize(item)
		y = y - size[2] - spacing
		widget.setPosition(item, { widget.getPosition(item)[1], y })
	end
end

-- Extractors and xeno labs

function getExtractionMats(recipes, station)
	for _, recipe in pairs(recipes) do
		for mat, _ in pairs(recipe.inputs) do
			-- sanity check: mat must be a string else root.createItem will fail
			if type(mat) ~= 'string' then
				sb.logWarn("Name '%s' is not a string - botched recipe? inputs = %s outputs = %s", mat, recipe.inputs, recipe.outputs)
			else
				registerMaterial(mat, station)
			end
		end
		for mat, _ in pairs(recipe.outputs) do
			if type(mat) ~= 'string' then
				sb.logWarn("Name '%s' is not a string - botched recipe? inputs = %s outputs = %s", mat, recipe.inputs, recipe.outputs)
			else
				registerMaterial(mat, station)
			end
		end
	end
end

function doExtraction(list, recipes, itemIn, itemOut, objectName)
	local conf = root.itemConfig({name = objectName})
	local techLevel = conf.config.fu_stationTechLevel
	local output = false

	addHeadingItem(conf, list)

	if itemIn then
		local listresults = {}
		for index, recipe in pairs(recipes) do
			if recipe.inputs[itemIn] or (recipe.reversible and checkValue(recipe.outputs[itemIn], techLevel)) then
				for item, _ in pairs(recipe.outputs) do
					if not materialsMissing[item] then
						listresults[item] = index
						output = true
					end
				end
			end
		end
		if output then
			output = addTextItem("=>", concatExtracted(listresults, recipes, techLevel, nil, itemIn, true), list) -- reverse ins/outs
		end
	elseif itemOut then
		local listresults = {}
		for index, recipe in pairs(recipes) do
			if checkValue(recipe.outputs[itemOut], techLevel) or (recipe.reversible and recipe.inputs[itemOut]) then
				for item, _ in pairs(recipe.inputs) do
					if not materialsMissing[item]  then -- and checkvalue(recipe.inputs[item],techLevel) -- NOTE : do we need to check again ?
						listresults[item] = index
						output = true
					end
				end
			end
		end
		if output then
			output = addTextItem("<=", concatExtracted(listresults, recipes, techLevel, nil,itemOut), list)
		end
	end

	if not output then doNothing(itemIn, list) end
end

function checkValue(counts, techLevel)
	if type(counts) == 'table' then return counts[techLevel] ~= nil end
	return counts ~= nil
end

function concatExtracted(list, recipes, techLevel, sep, itemInOut, InOutReverse)
	-- InOutReverse allows to decide whether itemInOut is an In or an Out
	-- blue for ratio > 1
	-- green for ratio 1
	-- red for ratio 1 / 50
	-- orange for 1/25
	-- ...
	if list == nil then return sep or "" end
	local out = ""
	local sep2 = ""
	for item, k in pairs(list) do -- k is a list of all indexed valid recipes
		local ratio = nil
		local inps = recipes[k].inputs
		local outs = recipes[k].outputs
		local itemA = InOutReverse and item or itemInOut
		local itemB = InOutReverse and itemInOut or item
		--sb.logWarn("output/input %s/%s  techlevel %s", outs, inps, techLevel)
		if inps ~= nil and outs ~= nil and outs[itemA] ~= nil and inps[itemB] ~= nil then --
			--sb.logWarn("type %s / %s", type(outs[itemA]), type(inps[itemB]))
			local multiplier = (type(outs[itemA]) == "table" and outs[itemA][techLevel] ~= nil and outs[itemA][techLevel]) or outs[itemA]
			local divisor = (type(inps[itemB]) == "table" and inps[itemB][techLevel] ~= nil and inps[itemB][techLevel]) or inps[itemB]
			ratio =  multiplier/divisor
		end
		--sb.logWarn("crafting ratio of %s/%s is %s", itemA, itemB, ratio)
			if ratio then
				local colour =  ratio > 1 and "^green;"
					or ratio == 1 and "^darkgreen;"
					or ratio >= 0.1 and "^yellow;"
					or ratio >= 0.04 and "^orange;"
					or "^red;"
					--or string.format("^#FF%02X00;", math.floor(ratio*800))
				out = out .. sep2 .. itemName(item,colour)
			else
				out = out .. sep2 .. itemName(item,"^gray;")
			end
			sep2 = sep or ", "
	end
	return out
end

-- Liquid Mixer

function doLiquidInteraction(list, recipes, itemIn, itemOut, objectName)
	local conf = root.itemConfig({name = objectName})
	local output = false

	addHeadingItem(conf, list)
	--sb.logWarn("liquids : in %s out %s",itemIn,itemOut)

	if itemIn then
		if itemIn ~= "liquidelderfluid" then
			for _, recipe in pairs(recipes) do
				if recipe.inputs[itemIn] then --or (recipe.reversible and checkValue(recipe.outputs[itemIn], techLevel))
					for item, resultquantity in pairs(recipe.outputs) do
						if not materialsMissing[item] then
							output = addTextItem("=",concatLiquid(recipe.inputs, nil," & ") .. " >> " .. concatLiquid(recipe.outputs, resultquantity), list)
						end
					end
				end
			end
		else
			output = addTextItem("=", "??? & ??? >> ???", list)
		end
	elseif itemOut then
		if itemOut ~= "liquidelderfluid" then
			local listitems={}
			local k = 0
			for _, recipe in pairs(recipes) do
				if  recipe.outputs[itemOut] then -- checkValue(recipe.outputs[itemOut], techLevel) or (recipe.reversible and recipe.inputs[itemOut]) then
					for item, _ in pairs(recipe.inputs) do
						k=k+1
						if not materialsMissing[item] then
							listitems[k] = concatLiquid(recipe.inputs, nil," & ")
							output = true
						end
					end
				end
			end
			-- remove dupes
			local hash = {}
			local result = {}
			for _,v in ipairs(listitems) do
				if (not hash[v]) then
					result[#result+1] = v
					hash[v] = true
				end
			end

			if output then
				for index, inputs in pairs(result) do
					addTextItem("<=", inputs,list)
				end
			end
		else
			output = addTextItem("<=", "??? & ???", list)
		end
	end

	if not output then doNothing(itemIn, list) end
end

function concatLiquid(list, resultquantity, sep)
	if list == nil then return sep or "" end
	local out = ""
	local sep2 = ""

	for item, counts in pairs(list) do
			if materials[item] then
				if resultquantity then
					local colour =  string.format("^#FF%02X00;", math.floor(resultquantity*80+70))
					out = out .. sep2 .. itemName(item,colour)
				else
					out = out .. sep2 .. itemName(item)
				end
				sep2 = sep or ", "
			end
	end
	return out
end


-- Separators and smelters

function getSepSmeltMats(recipes, station)
	for input, output in pairs(recipes.main) do
		registerMaterial(input, station)
		registerMaterial(output, station)
	end
	for input, outputs in pairs(recipes.extra) do
		registerMaterial(input, station)
		for output, _ in pairs(outputs) do
			registerMaterial(output, station)
		end
	end
end

function doSepOrSmelt(list, recipes, itemIn, itemOut)
	local output = false
	addHeadingItem(recipes, list)

	if itemIn then
		if recipes.main[itemIn] or recipes.extra[itemIn] then
			output = addTextItem("=>", concatRandom(recipes.extra[itemIn], recipes.main, itemIn), list)
		end
	elseif itemOut then
		local listitems = {}
		local listitemsextra = {}
		for input, outputs in pairs(recipes.main) do
			if outputs == itemOut then
				listitems[input] = true
				output = true
			end
		end
		for input, outputs in pairs(recipes.extra) do
			if outputs[itemOut] then
				listitemsextra[input] = outputs[itemOut]
				output = true
			end
		end
		if output then
			output = addTextItem("<=", concatRandom(listitemsextra, listitems, itemOut, true), list)
		end
	end

	if not output then doNothing(itemIn, list) end
end

function concatRandom(list, guaranteed,itemA,expand)
	local out = ""
	local sep = ""
	if guaranteed then -- probably unnecessary though better safe than sorry
		if not expand then
			out = guaranteed[itemA] and itemName(guaranteed[itemA]) or ""
			sep = guaranteed[itemA] and materials[guaranteed[itemA]] and ", " or ""
		else -- expand exists means guaranteed should be treated as a list
			for input, _ in pairs(guaranteed) do --lose true values
				out = out .. sep .. itemName(input)
				sep = ", "
			end
		end
	end
	if list then
		for item, chance in pairs(list) do
			if materials[item] then
				local colour = chance <= 25
					   and string.format("^#FF%02X00;", math.floor(chance * chance * 255 / 625))
						or string.format("^#%02XFF00;", math.floor((10000 - chance * chance) * 255 / 9375))
				out = out .. sep .. itemName(item, colour)
				sep = ', '
			end
		end
	end
	return out
end

-- Separators

function getSeparatorMats(recipes, station)
	local conf = root.itemConfig({name = station})
	local centrifugeType = conf.config.centrifugeType

	for _, recipeGroup in pairs(recipes.recipeTypes[centrifugeType]) do
		for input, outputs in pairs(recipes[recipeGroup]) do
			registerMaterial(input, station)
			for output, _ in pairs(outputs) do
				registerMaterial(output, station)
			end
		end
	end
end

function doSeparate(list, recipes, itemIn, itemOut, objectName)
	local output = false
	local conf = root.itemConfig({name = objectName})
	addHeadingItem(conf, list)
	local centrifugeType = conf.config.centrifugeType
	local recipeGroups = recipes.recipeTypes[centrifugeType]

	if itemIn then
		for i = #recipeGroups,1,-1 do
			local recipeGroup = recipes[recipeGroups[i]]
			if recipeGroup[itemIn] and not output then
				output = addTextItem("=>", concatSepRandom(recipeGroup[itemIn], conf.config.itemChances), list)
			end
		end
	elseif itemOut then
		local listitems = {}
		for i = #recipeGroups,1,-1 do
			local recipeGroup = recipes[recipeGroups[i]]
			for input, outputs in pairs(recipeGroup) do
				if outputs[itemOut] then
					local iname = itemName(input,"^grey;")
					if iname then -- check because some sifter recipes are for mods & could not exist
						listitems[input] = outputs[itemOut] -- extract chances to make itemout from input
						output = true
					end
				end
			end
		end
		if output then
			output = addTextItem("<=", concatSepRandom(listitems, conf.config.itemChances), list)
		end
	end

	if not output then doNothing(itemIn, list) end
end

function concatSepRandom(list, chanceTable)
	if list == nil then return "" end

	local out = ""
	local sep = ""
	for item, chancePair in pairs(list) do
		if materials[item] then
			local chanceBase, chanceDivisor = table.unpack(chancePair)
			local chance = chanceTable[chanceBase] / chanceDivisor * 100
			local colour = chance <= 25
				   and string.format("^#FF%02X00;", math.floor(chance * chance * 255 / 625))
					or string.format("^#%02XFF00;", math.floor((10000 - chance * chance) * 255 / 9375))
			out = out .. sep .. itemName(item, colour)
			sep = ', '
		end
	end
	return out
end

-- General output generation helpers and utilities

function getNearbyStations()
	local nearby = world.objectQuery(world.entityPosition(pane.sourceEntity()), 150)
	if not nearby then
		return nil
	end

	local found = {}
	local foundone = false
	for _, id in pairs(nearby) do
		local name = world.entityName(id)
		-- local obj = processObjects[name]
		-- if obj and obj.map then name = obj.map end -- this was an exception for roof extractors, they don't exist anymore
		if recognisedObjectsKey[name] then --processObjects[name] -- why processobjects in here ??????
			found[name] = true
			foundone = true
		end
	end

	return found
end

function addHeadingItem(item, list)
	local path = string.format("%s.%s", RECIPES, widget.addListItem(RECIPES))
	widget.setText(path .. ".text", item.name or item.config.shortdescription)
	widget.setImage(path .. ".icon", item.icon or rescale(canonicalise(item.config.inventoryIcon, item.directory), 18, 18))
	widget.setVisible(path .. ".icon", true)
	table.insert(list, path)
end

function canonicalise(file, directory)
	if string.sub(file, 1, 1) == '/' then return file end
	return directory .. file
end

function rescale(image, x, y)
	local size = root.imageSize(image)
	if size[1] <= x and size[2] <= y then return image end
	return image .. '?scalebilinear=' .. math.min(x / size[1], y / size[2])
end

function addTextItem(direction, text, list)
	-- sb.logWarn("Crafting Info Display - is displaying :  '%s'", text)
	local path = string.format("%s.%s", RECIPES, widget.addListItem(RECIPES))
	widget.setText(path .. ".text", text)
	if direction then widget.setText(path .. ".direction", direction) end
	table.insert(list, path)
	return true
end

function addTextToList(direction, text, list)
	local path = string.format("%s.%s", RECIPES, widget.addListItem(RECIPES))
	widget.setText(path .. ".text", text)
	if direction then widget.setText(path .. ".direction", direction) end
	table.insert(list, path)
	return true
end

function itemName(item, colour)
	if not materials[item] then return nil end
	return (colour or "^green;") .. (materials[item].name or materials[item].config.shortdescription) .. "^reset;"
end

function doNothing(isInput, list)
	addTextItem(nil, isInput and "not processed by this station" or "not output by this station", list)
end
