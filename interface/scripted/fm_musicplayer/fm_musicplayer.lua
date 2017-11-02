require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
    self.itemList = "scrollArea.itemList"
    self.availableTechs = {}
    self.currentList = {}
    self.selectedItem = nil
    self.category = ""
    self.selectedTech = ""

    self.currentFilter = ""
    self.availableFilter = false
    self.currentSearch = ""

    populateItemList()
end

function update(dt)
    updateSearch()
    updateCounts()
    reloadCraftable()
    populateItemList()
end

function reloadCraftable()
    for _,v in pairs(self.currentList or {}) do
        widget.setVisible(v..".notcraftableoverlay")
    end
end

function updateSearch()
    self.currentSearch = string.lower(widget.getText("filter"))
    self.availableFilter = widget.getChecked("btnFilterHaveMaterials")
end

function updateCounts()
    local listItem = widget.getListSelected(self.itemList)

    local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
end

function populateItemList(forceRepop)
    local shopTechs = config.getParameter("music")
    local availableTechs = {}
    for _,v in pairs(shopTechs) do
        local legit = true

        if legit and (self.currentFilter ~= "") then
            legit = v.category == self.currentFilter
        end

        if legit and (self.currentSearch ~= "") then
            -- Search by item name and then by tech name
            legit = (v.name and (string.find(v.name:lower(), self.currentSearch) ~= nil))
        end

        if legit then table.insert(availableTechs, v) end
    end

    if forceRepop or not compare(availableTechs, self.availableTechs) then
        self.availableTechs = availableTechs
        widget.clearListItems(self.itemList)
        widget.setButtonEnabled("btnUpgrade", false)

        self.currentList = {}

        for i, tech in ipairs(self.availableTechs) do

            local listWidget = widget.addListItem(self.itemList)
            local listItem = string.format("%s.%s", self.itemList, listWidget)
            table.insert(self.currentList, listItem)


            widget.setText(listItem..".itemName", tech.name)
            widget.setItemSlotItem(listItem..".itemIcon", tech.icon or "fm_placeholder")

            widget.setData(listItem,
            {
                index = i,
                tech = tech.name,
				image = tech.image,
				description = tech.description
            })

            widget.setVisible(listItem..".moneyIcon", false)
            widget.setText(listItem..".priceLabel", "")
            widget.setVisible(string.format("%s.notcraftableoverlay", listItem))

            if tech.name == self.selectedTech then
                widget.setListSelected(self.itemList, listWidget)
            end
        end

        self.selectedItem = nil
        setCanUnlock(nil)
    end
end

function setCanUnlock(recipe)
	if recipe then
		widget.setButtonEnabled("btnCraft", true)
	else
		widget.setButtonEnabled("btnCraft", false)
	end
end

function itemSelected()
    local listItem = widget.getListSelected(self.itemList)
    self.selectedItem = listItem

    if listItem then
        local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
        setCanUnlock("unlock")
        self.selectedTech = itemData.tech

        widget.setText("techDescription", itemData.description or "Replaces the background music with the selected one. The music player object plays music when a player is nearby and the music player is switched on. The portable music player plays music until the music is changed or reset.")
        widget.setImage("techIcon", itemData.image or "/items/generic/fm_placeholder.png")
    end
end

function doUnlock()
    if self.selectedItem then
        local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
        local tech = self.availableTechs[selectedData.index]
		
        if tech then
			local entityID = pane.sourceEntity()
			local entityType = world.entityType(entityID)
			music = {}
			table.insert(music, tech.musicDirectory)
			if entityType == "object" then
				world.sendEntityMessage(entityID, "changeMusic", music)
				pane.dismiss()
			else
				world.sendEntityMessage(player.id(), "playAltMusic", music, 2.0)
				pane.dismiss()
			end
        end

        populateItemList(true)
    end
end

function categories()
    local data = widget.getSelectedData("categories")
    if data then
        self.currentFilter = data.filter
    end
end