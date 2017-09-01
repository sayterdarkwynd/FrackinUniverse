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
        widget.setVisible(v..".notcraftableoverlay", not hasIngredients(widget.getData(v).recipe))
    end
end

function updateSearch()
    self.currentSearch = string.lower(widget.getText("filter"))
    self.availableFilter = widget.getChecked("btnFilterHaveMaterials")
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
            widget.setText("ingLabel"..i, player.hasCountOfItem(ingredient.name).."/"..ingredient.count)
            if player.hasCountOfItem(ingredient.name) < ingredient.count then
                widget.setFontColor("ingLabel"..i, "red")
            else
                widget.setFontColor("ingLabel"..i, "white")
            end
        else
            break
        end
    end
end

function populateItemList(forceRepop)
    local shopTechs = config.getParameter("techs")
    local availableTechs = {}
    for _,v in pairs(shopTechs) do
        local legit = true

        -- test for prerequisite techs
        if v.prereq then
            for _,p in pairs(v.prereq or {}) do
                local found = false
                for d,x in pairs(player.enabledTechs()) do
                    if x == p then found = true break end
                end
                if not found then legit = false break end
            end
        end

        -- test for completed quests
        if v.mission then
            for _,p in pairs(v.mission) do
                if not player.hasCompletedQuest(p) then legit = false break end
            end
        end

        -- test for recipe learned
        if legit and v.recipeReq then
            legit = player.blueprintKnown(v.item)
        end

        if legit and (self.currentFilter ~= "") then
            legit = root.techConfig(v.name).type == self.currentFilter
        end

        if legit and (self.currentSearch ~= "") then
            -- Search by item name and then by tech name
            legit = (v.item and (string.find(v.item:lower(), self.currentSearch) ~= nil)) or
                    (string.find(root.techConfig(v.name).shortDescription:lower(), self.currentSearch) ~= nil)
        end

        if legit and self.availableFilter then
            legit = hasIngredients(v.recipe)
        end

        if legit then table.insert(availableTechs, v) end
    end

    if forceRepop or not compare(availableTechs, self.availableTechs) then
        self.availableTechs = availableTechs
        widget.clearListItems(self.itemList)
        widget.setButtonEnabled("btnUpgrade", false)

        self.currentList = {}

        for i, tech in ipairs(self.availableTechs) do
            local config = root.techConfig(tech.name)

            local listWidget = widget.addListItem(self.itemList)
            local listItem = string.format("%s.%s", self.itemList, listWidget)
            table.insert(self.currentList, listItem)

            local name = config.shortDescription

            widget.setText(listItem..".itemName", name)
            widget.setItemSlotItem(listItem..".itemIcon", root.createItem(tech.item or "techcard"))

            widget.setData(listItem,
            {
                index = i,
                tech = tech.name,
                recipe = tech.recipe
            })

            widget.setVisible(listItem..".moneyIcon", false)
            widget.setText(listItem..".priceLabel", "")
            widget.setVisible(string.format("%s.notcraftableoverlay", listItem), not hasIngredients(tech.recipe))

            if tech.name == self.selectedTech then
                widget.setListSelected(self.itemList, listWidget)
            end

            for i,v in ipairs(player.availableTechs()) do
                if v == tech.name then
                    widget.setVisible(listItem..".newIcon", false)
                    break
                end
            end
        end

        self.selectedItem = nil
        setCanUnlock(nil)
    end
end

function setCanUnlock(recipe)
    local enableButton = false

    if recipe then
        enableButton = hasIngredients(recipe)
    end

    widget.setButtonEnabled("btnCraft", enableButton)
end

function itemSelected()
    local listItem = widget.getListSelected(self.itemList)
    self.selectedItem = listItem

    if listItem then
        local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
        setCanUnlock(itemData.recipe)
        self.selectedTech = itemData.tech

        widget.setText("techDescription", root.techConfig(itemData.tech).description)
        widget.setImage("techIcon", root.techConfig(itemData.tech).icon)

        for i=1,4 do
            if itemData.recipe[i] then
                widget.setItemSlotItem("ingredient"..i, root.createItem(itemData.recipe[i].name))
                widget.setText("ingLabel"..i, player.hasCountOfItem(itemData.recipe[i].name).."/"..itemData.recipe[i].count)
                widget.setText("ingName"..i, root.itemConfig(itemData.recipe[i].name).config.shortdescription)
                if player.hasCountOfItem(itemData.recipe[i].name) < itemData.recipe[i].count then
                    widget.setFontColor("ingLabel"..i, "red")
                else
                    widget.setFontColor("ingLabel"..i, "white")
                end
            else
                widget.setItemSlotItem("ingredient"..i, nil)
                widget.setText("ingName"..i, "")
                widget.setText("ingLabel"..i, "")
            end
        end
    else
        for i=1,4 do
            widget.setItemSlotItem("ingredient"..i, nil)
            widget.setText("ingLabel"..i, "")
        end

        widget.setText("techDescription", "")
        widget.setImage("techIcon", "")
    end
end

function doUnlock()
    if self.selectedItem then
        local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
        local tech = self.availableTechs[selectedData.index]

        local legit = true
        if tech then
            for k,v in pairs(selectedData.recipe) do
                if player.hasCountOfItem(v.name) < v.count then
                    legit = not legit
                end
            end

            if legit or player.isAdmin() then
                for k,v in pairs(selectedData.recipe) do
                    player.consumeItem(v.name, v.count)
                end
                player.makeTechAvailable(tech.name)
                player.enableTech(tech.name)
                if tech.item then
                    player.giveItem(tech.item)
                end
            end
        end

        populateItemList(true)
    end
end

function hasIngredients(recipe)
    -- hax for the hax god
    if player.isAdmin() then return true end

    for k,v in pairs(recipe) do
        if player.hasCountOfItem(v.name) < v.count then
            return false
        end
    end
    return true
end

function categories()
    local data = widget.getSelectedData("categories")
    if data then
        self.currentFilter = data.filter
    end
end
