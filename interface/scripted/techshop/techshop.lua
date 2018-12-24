require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.itemList = "scrollArea.itemList"
	self.availableTechs = {}						-- Techs that are unlocked
	self.lockedTechs = config.getParameter("techs") -- Techs that aren't unlocked (don't have recipe)
	self.currentList = {}						    -- Current list items in the widget
	self.selectedData = nil						    -- Current selected tech data
	self.selectedTech = ""						    -- Current selected tech (for remembering position)

	self.currentFilter = ""						    -- Current selected category filter (head, body, legs)
	self.availableFilter = false					-- Whether the materials available filter is checked
	self.currentSearch = ""						    -- Current search filter

	self.forceRepop = true						    -- Whether to repopulate the list next update
	
	categories()
	-- initializing the available techs
	for i,tech in ipairs(self.lockedTechs) do
		if tech.race and not contains(tech.race, player.species()) then
			self.lockedTechs[i] = nil
		elseif not tech.recipeReq or player.blueprintKnown(tech.item) then
			table.insert(self.availableTechs, tech)
			self.lockedTechs[i] = nil  -- nil instead of table.remove to preserve order
		end
	end

	widget.setButtonEnabled("btnCraft", false)
end

function update(dt)
	-- put this here to remove flickering
	if self.adminMode and not player.isAdmin() then
		self.availableTechs = {}
		self.lockedTechs = config.getParameter("techs")
		self.adminMode = false
		self.forceRepop = true
	end

	-- each update, check to see if any new techs have been unlocked, and update accordingly
	for i,tech in pairs(self.lockedTechs) do
		if player.blueprintKnown(tech.item) then
			local newPos = i
			if newPos > #self.availableTechs + 1 then -- if it's over the end, append to the end
				newPos = #self.availableTechs + 1
			end
			table.insert(self.availableTechs, newPos, tech) -- making sure the ordering remains intact
			self.lockedTechs[i] = nil  -- again, nil to preserve ordering
			self.forceRepop = true	 -- repopulate the list if there's a change
		end
	end

	-- Admin players get access to all techs
	if player.isAdmin() then
		self.availableTechs = config.getParameter("techs")
		if not self.adminMode then
			self.adminMode = true
			self.forceRepop = true
		end
	end

	updateSearch()
	updateIngredients()
	populateItemList(self.forceRepop)
	reloadCraftable()

	self.forceRepop = false
end

function reloadCraftable()
	for _,v in pairs(self.currentList or {}) do
		widget.setVisible(v..".notcraftableoverlay", not canCraft(widget.getData(v)))
	end
end

function updateSearch()
	local newSearch = string.lower(widget.getText("filter"))
	if self.currentSearch ~= newSearch then
		self.currentSearch = newSearch
		self.forceRepop = true
	end
end

function populateItemList(forceRepop)
	-- Only repopulate the list when conditions change! Cuts down on lag by ten zillion %
	if forceRepop then
		local selectFound = false

		widget.clearListItems(self.itemList)
		widget.setButtonEnabled("btnUpgrade", false)

		self.currentList = {}

		for i,tech in ipairs(self.availableTechs) do
			local config = root.techConfig(tech.name)
			local name = config.shortDescription
			local legit = true

			if legit and (self.currentFilter ~= "") then
				legit = config.type == self.currentFilter
			end

			if legit and (self.currentSearch ~= "") then
				-- Search by item name and then by tech name
				legit = (tech.item and (string.find(tech.item:lower(), self.currentSearch) ~= nil)) or
						(string.find(name:lower(), self.currentSearch) ~= nil)
			end

			if legit and self.availableFilter then
				legit = canCraft(tech)
			end

			if legit then
				local listWidget = widget.addListItem(self.itemList)
				local listItem = string.format("%s.%s", self.itemList, listWidget)
				table.insert(self.currentList, listItem)

				widget.setText(listItem..".itemName", name)
				widget.setItemSlotItem(listItem..".itemIcon", root.createItem(tech.item or "techcard"))

				if contains(player.enabledTechs(), tech.name) then
					widget.setVisible(listItem..".newIcon", false)
					tech.owned = true
				end

				widget.setData(listItem,
				{
					index = i,
					tech = tech.name,
					recipe = tech.recipe,
					prereq = tech.prereq,
					owned = tech.owned,
					item = tech.item
				})

				widget.setVisible(listItem..".moneyIcon", false)
				widget.setText(listItem..".priceLabel", "")
				widget.setVisible(string.format("%s.notcraftableoverlay", listItem), not canCraft(tech))

				if tech.name == self.selectedTech then
					widget.setListSelected(self.itemList, listWidget)
				end
			end
		end
	end
end

function setCanUnlock()
	local enableButton = false

	if self.selectedData then
		enableButton = canCraft(self.selectedData)
	end
	
	widget.setButtonEnabled("btnCraft", enableButton)
end

function itemSelected()
	updateSelected()
	if self.selectedData then self.selectedTech = self.selectedData.tech end
	swapRecipe()
end

function doUnlock()
	if self.selectedData then
		local tech = self.selectedData
		if tech then
			local craftable = canCraft(tech)
			
			if not (craftable or player.isAdmin()) then return end
			
			for k,v in pairs(tech.recipe) do
				if isCurrency(v) then
					player.consumeCurrency(v.name, v.count)
				else
					player.consumeItem(v)
				end
			end
			
			if tech.item then
				world.sendEntityMessage(player.id(), "addCollectable", "fu_tech", tech.item)
				local techItem = root.itemConfig(tech.item)
				local techBlueprints = techItem.config.learnBlueprintsOnPickup
				for _,blueprint in pairs (techBlueprints or {}) do
					player.giveBlueprint(blueprint)
				end
			end
			
			player.makeTechAvailable(tech.tech)
			player.enableTech(tech.tech)
			populateItemList(true)
		end
	end
end

function hasPrereqs(prereqs)
	if player.isAdmin() then return true end
	for _,p in pairs(prereqs or {}) do
		if not contains(player.enabledTechs(), p) then return false end
	end
	return true
end

function hasIngredients(recipe)
	-- hax for the hax god
	if player.isAdmin() then return true end

	for k,v in pairs(recipe) do
		if not hasEnough(v) then
			return false
		end
	end
	return true
end

function categories()
	local data = widget.getSelectedData("categories")
	if data then
		if self.currentFilter ~= data.filter then
			self.forceRepop = true
		end
		self.currentFilter = data.filter
	end
end

function materialFilter()
	self.availableFilter = widget.getChecked("btnFilterHaveMaterials")
	self.forceRepop = true
end

function swapRecipe()
	updateIngredients()
	setCanUnlock()
	
	if self.selectedData then
		if not hasPrereqs(self.selectedData.prereq) then
			local missing = ""
			for _,p in pairs(self.selectedData.prereq or {}) do
				local found = false
				for d,x in pairs(player.enabledTechs()) do
					if x == p then found = true break end
				end
				if not found then missing = missing.."  - "..root.techConfig(p).shortDescription.."\n" end
			end								 --  Preliminary research required:
			widget.setText("techDescription", "^red;Preliminary research required:\n"..missing.."^reset;")
		else
			widget.setText("techDescription", root.techConfig(self.selectedData.tech).description)
		end
		
		widget.setImage("techIcon", root.techConfig(self.selectedData.tech).icon)
	else
		widget.setText("techDescription", "")
		widget.setImage("techIcon", "")
	end
end

function updateIngredients()
	local recipe = {}
	if self.selectedData then
		recipe = self.selectedData.recipe
	end
	
	for i=1,4 do
		if recipe[i] then
			local ingredient = recipe[i]
			widget.setItemSlotItem("ingredient"..i, root.createItem(ingredient.name))
			widget.setText("ingLabel"..i, getAmount(ingredient).."/"..ingredient.count)
			widget.setText("ingName"..i, root.itemConfig(ingredient.name).config.shortdescription)
			if hasEnough(ingredient) then
				widget.setFontColor("ingLabel"..i, "white")
			else
				widget.setFontColor("ingLabel"..i, "red")
			end
		else
			widget.setItemSlotItem("ingredient"..i, nil)
			widget.setText("ingName"..i, "")
			widget.setText("ingLabel"..i, "")
		end
	end
end

function updateSelected()
	local listItem = widget.getListSelected(self.itemList)
	self.selectedData = listItem and widget.getData(string.format("%s.%s", self.itemList, listItem)) or nil
end

function isCurrency(item)
	return root.itemType(item.name) == "currency"
end

function currencyType(item)
	if item.parameters and item.parameters.currency then
		return item.parameters.currency
	end
	return root.itemConfig(item).config["currency"]
end

function getAmount(item)
	if isCurrency(item) then
		return player.currency(currencyType(item))
	else
		return player.hasCountOfItem(item.name)
	end
end

function hasEnough(item)
	return getAmount(item) >= item.count
end

function canCraft(tech)
	return hasIngredients(tech.recipe) and hasPrereqs(tech.prereq) and not tech.owned
end
