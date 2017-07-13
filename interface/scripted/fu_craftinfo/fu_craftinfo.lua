--[[ not doing honey centrifuges & extractors just yet
require "/objects/bees/centrifuge.lua"
beeCentrifuge = deciding() -- input: {outputs}

require "objects/bees/honeymap.lua"
...
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

initialised = false

function init()
	extractionLab = root.assetJson("/objects/generic/extractionlab_recipes.config") -- {inputs}, {outputs}
	xenoLab = root.assetJson('/objects/generic/xenostation_recipes.config') -- {inputs}, {outputs}
	centrifugeLab = root.assetJson("/objects/generic/centrifuge_recipes.config")  -- it's more complicated than the above two

	self.matfilter = getFilter()
	script.setUpdateDelta(1)

	if initialised then return end
	initialised = true

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

	processObjects = {
		extractionlab         = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		extractionlab_roof    = { map = "extractionlab" },
		extractionlabadv      = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		extractionlabadv_roof = { map = "extractionlabadv" },
		quantumextractor      = { mats = getExtractionMats, spew = doExtraction, data = extractionLab },
		quantumextractor_roof = { map = "quantumextractor" },
		xenostation           = { mats = getExtractionMats, spew = doExtraction, data = xenoLab },
		xenostationadvnew     = { mats = getExtractionMats, spew = doExtraction, data = xenoLab },
		centrifuge            = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		centrifuge2           = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		industrialcentrifuge  = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		ironcentrifuge        = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		woodencentrifuge      = { mats = getSeparatorMats, spew = doSeparate, data = centrifugeLab },
		fu_blastfurnace       = { mats = getSepSmeltMats, spew = doSepOrSmelt, data = blastFurnace },
		isn_arcsmelter        = { mats = getSepSmeltMats, spew = doSepOrSmelt, data = arcSmelter }
	}
	recognisedObjects = {
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
		"isn_arcsmelter",
		"fu_blastfurnace"
	}

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

end

function update()
	script.setUpdateDelta(0)
	populateMaterialsList()
end

function getFilter()
	return widget.getText('tbFind'):gsub('^ +', ''):gsub(' +$', ''):gsub('  +', ' '):lower()
end

function onInteraction(args)
end

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
		if not sapling and root.createItem({ name = mat }).name == 'perfectlygenericitem' then
			materialsMissing[mat] = true
			sb.logWarn("Crafting Info Display found non-existent item '%s'", mat)
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
	local listed = false
	local found = getNearbyStations()

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

	if not itemIn and not itemOut then
		widget.setVisible(BLANK, true)
		return
	end

	local found = getNearbyStations()
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
		for _, recipe in pairs(recipes) do
			if recipe.inputs[itemIn] or (recipe.reversible and checkValue(recipe.outputs[itemIn], techLevel)) then
				for item, _ in pairs(recipe.outputs) do
					if not materialsMissing[item] then
						output = addTextItem("=>", concatExtracted(recipe.outputs, techLevel), list)
					end
				end
			end
		end
	elseif itemOut then
		for _, recipe in pairs(recipes) do
			if checkValue(recipe.outputs[itemOut], techLevel) or (recipe.reversible and recipe.inputs[itemOut]) then
				for item, _ in pairs(recipe.inputs) do
					if not materialsMissing[item] then
						output = addTextItem("<=", concatExtracted(recipe.inputs, techLevel), list)
					end
				end
			end
		end
	end

	if not output then doNothing(itemIn, list) end
end

function checkValue(counts, techLevel)
	if type(counts) == 'table' then return counts[techLevel] ~= nil end
	return counts ~= nil
end

function concatExtracted(list, techLevel, sep)
	if list == nil then return sep or "" end
	local out = sep or ""
	local sep = sep and ", " or ""
	for item, counts in pairs(list) do
		if checkValue(counts, techLevel) then
			if materials[item] then
				out = out .. sep .. itemName(item)
				sep = ', '
			end
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
			output = addTextItem("=>", concatRandom(recipes.extra[itemIn], recipes.main[itemIn]), list)
		end
	elseif itemOut then
		for input, outputs in pairs(recipes.main) do
			if outputs[itemOut] then
				output = addTextItem("<=", input, list)
			end
		end
	end

	if not output then doNothing(itemIn, list) end
end

function concatRandom(list, guaranteed)
	if list == nil then return guaranteed and itemName(guaranteed) or "" end

	local out = guaranteed and itemName(guaranteed) or ""
	local sep = guaranteed and materials[guaranteed] and "; " or ""
	for item, chance in pairs(list) do
		if item ~= guaranteed and materials[item] then
			local colour = chance <= 25
				   and string.format("^#FF%02X00;", math.floor(chance * chance * 255 / 625))
				    or string.format("^#%02XFF00;", math.floor((10000 - chance * chance) * 255 / 9375))
			out = out .. sep .. itemName(item, colour)
			sep = ', '
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
		for i = #recipeGroups,1,-1 do
			if not output then
				local recipeGroup = recipes[recipeGroups[i]]
				for input, outputs in pairs(recipeGroup) do
					if outputs[itemOut] then
						output = addTextItem("<=", input, list)
					end
				end
			end
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
		local obj = processObjects[name]
		if obj and obj.map then name = obj.map end
		if processObjects[name] then
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
