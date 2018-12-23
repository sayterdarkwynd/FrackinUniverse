require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.itemList = "scrollArea.itemList"
	self.availableTechs = {}						-- Techs that are unlocked
	self.lockedTechs = config.getParameter("techs") -- Techs that aren't unlocked (don't have recipe)
	self.currentList = {}						   -- Current list items in the widget
	self.selectedItem = nil						 -- Current selected item in list widget
	self.selectedTech = ""						  -- Current selected tech (for remembering position)

	self.currentFilter = ""						 -- Current selected category filter (head, body, legs)
	self.availableFilter = false					-- Whether the materials available filter is checked
	self.currentSearch = ""						 -- Current search filter

	self.forceRepop = true						  -- Whether to repopulate the list next update
	
	categories()
	-- initializing the available techs
	for i,tech in ipairs(self.lockedTechs) do
		if not tech.recipeReq or player.blueprintKnown(tech.item) then
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
	updateCounts()
	populateItemList(self.forceRepop)
	reloadCraftable()

	self.forceRepop = false
end

function reloadCraftable()
	for _,v in pairs(self.currentList or {}) do
		widget.setVisible(v..".notcraftableoverlay", not hasIngredients(widget.getData(v).recipe))
	end
end

function updateSearch()
	local newSearch = string.lower(widget.getText("filter"))
	if self.currentSearch ~= newSearch then
		self.currentSearch = newSearch
		self.forceRepop = true
	end
end

function updateCounts()
	local listItem = widget.getListSelected(self.itemList)
	if not listItem then
		for i=1,4 do
			widget.setItemSlotItem("ingredient"..i, nil)
			widget.setText("ingLabel"..i, "")
			widget.setText("ingName"..i, "")
		end
		return
	end

	local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))

	for i=1,4 do
		local ingredient = itemData.recipe[i]
		if ingredient then
			if isCurrency(ingredient) then
				widget.setText("ingLabel"..i, player.currency(ingredient.currency).."/"..ingredient.count)
			else
				widget.setText("ingLabel"..i, player.hasCountOfItem(ingredient.name).."/"..ingredient.count)
			end
			widget.setText("ingName"..i, root.itemConfig(ingredient.name).config.shortdescription)
			if hasEnough(ingredient) then
				widget.setFontColor("ingLabel"..i, "white")
			else
				widget.setFontColor("ingLabel"..i, "red")
			end
		else
			break
		end
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
				legit = hasIngredients(tech.recipe)
			end

			if legit then
				local listWidget = widget.addListItem(self.itemList)
				local listItem = string.format("%s.%s", self.itemList, listWidget)
				table.insert(self.currentList, listItem)

				widget.setText(listItem..".itemName", name)
				widget.setItemSlotItem(listItem..".itemIcon", root.createItem(tech.item or "techcard"))

				if contains(player.availableTechs(), tech.name) then
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
				widget.setVisible(string.format("%s.notcraftableoverlay", listItem), not (hasIngredients(tech.recipe) or hasPrereqs(tech.prereq)))

				if tech.name == self.selectedTech then
					widget.setListSelected(self.itemList, listWidget)
					self.selectedItem = listWidget
					selectFound = true
				end
			end
		end
		if not selectFound then self.selectedItem = nil end
	end
end

function setCanUnlock(itemData)
	local enableButton = false

	if itemData then
		enableButton = hasIngredients(itemData.recipe) and hasPrereqs(itemData.prereq)
	end
														-- eyyyyy more hax
	widget.setButtonEnabled("btnCraft", enableButton)
end

function itemSelected()
	local listItem = widget.getListSelected(self.itemList)
	self.selectedItem = listItem

	if listItem then
		local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
		setCanUnlock(itemData)
		self.selectedTech = itemData.tech

		if not hasPrereqs(itemData.prereq) then
			local missing = ""
			for _,p in pairs(itemData.prereq or {}) do
				local found = false
				for d,x in pairs(player.enabledTechs()) do
					if x == p then found = true break end
				end
				if not found then missing = missing.."  - "..root.techConfig(p).shortDescription.."\n" end
			end								 --  Preliminary research required:
			widget.setText("techDescription", "^red;Preliminary research required:\n"..missing.."^reset;")
		else
			widget.setText("techDescription", root.techConfig(itemData.tech).description)
		end
		widget.setImage("techIcon", root.techConfig(itemData.tech).icon)

		for i=1,4 do
			if itemData.recipe[i] then
				local ingredient = itemData.recipe[i]
				widget.setItemSlotItem("ingredient"..i, root.createItem(ingredient.name))
				if isCurrency(ingredient) then
					widget.setText("ingLabel"..i, player.currency(ingredient.currency).."/"..ingredient.count)
				else
					widget.setText("ingLabel"..i, player.hasCountOfItem(ingredient.name).."/"..ingredient.count)
				end
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
		widget.setItemSlotItem("currentRecipeIcon", root.createItem(itemData.item or "techcard"))
	else
		for i=1,4 do
			widget.setItemSlotItem("ingredient"..i, nil)
			widget.setText("ingLabel"..i, "")
			widget.setText("ingName"..i, "")
		end

		widget.setText("techDescription", "")
		widget.setImage("techIcon", "")
		widget.setButtonEnabled("btnCraft", false)
		widget.setItemSlotItem("currentRecipeIcon", nil)
	end
end

function doUnlock()
	if self.selectedItem then
		local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
		local tech = self.availableTechs[selectedData.index]

		local legit = true
		if tech then
			for k,v in pairs(selectedData.recipe) do
				if not hasEnough(v) then
					legit = not legit
					break
				end
			end

			if legit or player.isAdmin() then
				if not selectedData.owned and not player.isAdmin() then
					for k,v in pairs(selectedData.recipe) do
						if isCurrency(v) then
							player.consumeCurrency(v.name, v.count)
						else
							player.consumeItem(v)
						end
					end
				end
				player.makeTechAvailable(tech.name)
				player.enableTech(tech.name)
				if tech.item then
					world.sendEntityMessage(player.id(), "addCollectable", "fu_tech", tech.item)
					local techItem = root.itemConfig(tech.item)
					local techBlueprints = techItem.config.learnBlueprintsOnPickup
					for _,blueprint in pairs (techBlueprints or {}) do
						player.giveBlueprint(blueprint)
					end
				end
				populateItemList(true)
			end
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

function isCurrency(item)
	return root.itemType(item.name) == "currency"
end

function hasEnough(item)
	if isCurrency(item) then
		return player.currency(item.currency) >= item.count
	else
		return player.hasCountOfItem(item.name) >= item.count
	end
end
