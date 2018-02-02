require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

function init()
  self.list = "scrollArea.collectionList"
  self.customList = "scrollAreaCustom.customCollectionList"

  self.iconSize = config.getParameter("iconSize")

  self.currentCollectables = {}
  self.playerCollectables = {}

  populateList()
end

function update(dt)
-- BEGIN CUSTOM CODE: hack to work around list widget selection issues
  local selected = widget.getListSelected(self.customList)
  if selected then
    selected = widget.getData(string.format("%s.%s", self.customList, selected))
    if selected ~= self.collectionName then
      populateList(selected)
      self.customCollectionName = selected
      widget.setSelectedOption("collectionTabs", 6)
    end
    return
  end
-- END CUSTOM CODE
  if self.collectionName and self.collectionName ~= selected then
    local selected = widget.getSelectedData("collectionTabs")
    if self.collectionName ~= selected then
      populateList()
    else
      for _,collectable in pairs(player.collectables(self.collectionName)) do
        if not self.playerCollectables[collectable] then
          populateList(self.customCollectionName) --
          break
        end
      end
    end
  end
end

function populateList(collectionName)
-- BEGIN CUSTOM CODE
  local collectionName = collectionName or widget.getSelectedData("collectionTabs")
  if collectionName == "customCollectionsVisible" then return end -- special case: do nothing

  widget.clearListItems(self.customList)
-- END CUSTOM CODE
  widget.clearListItems(self.list)
  self.collectionName = collectionName
--BEGIN CUSTOM CODE
  if collectionName == "customCollections" then
    local collections = config.getParameter("customCollections")
    table.sort(collections)

    widget.setText("selectLabel", config.getParameter("customCollectionsTitle"))
    widget.setVisible("emptyLabel", false)
    widget.setVisible("scrollArea", false)
    widget.setVisible("scrollAreaCustom", true)

    for _,collection in pairs(collections) do
      local item = widget.addListItem(self.customList)
      local path = string.format("%s.%s", self.customList, item)
      local collectionInfo = root.collection(collection)
      widget.setData(path, collection)
      widget.setText(path .. ".collectionName", collectionInfo.title)
    end
-- END CUSTOM CODE -- below, self.collectionName → collectionName
  elseif collectionName then
    self.customCollectionName = collectionName -- CUSTOM - needed to avoid reset to custom collection view
    local collection = root.collection(collectionName)
    -- MOVED: setting of selectLabel
    widget.setVisible("emptyLabel", false)
    widget.setVisible("scrollArea", true)
    widget.setVisible("scrollAreaCustom", false)

    self.currentCollectables = {}

    self.playerCollectables = {}
    for _,collectable in pairs(player.collectables(collectionName)) do
      self.playerCollectables[collectable] = true
    end

    local collectables = root.collectables(collectionName)
    table.sort(collectables, function(a, b) return a.order < b.order end)
    local count = 0 -- CUSTOM
    local collected = 0 -- CUSTOM
    for _,collectable in pairs(collectables) do
      local item = widget.addListItem(self.list)
      
      if collectable.icon ~= "" then
        local imageSize = rect.size(root.nonEmptyRegion(collectable.icon))
        local scaleDown = math.max(math.ceil(imageSize[1] / self.iconSize[1]), math.ceil(imageSize[2] / self.iconSize[2]))

        if not self.playerCollectables[collectable.name] then
          collectable.icon = string.format("%s?multiply=000000", collectable.icon)
        else
          collected = collected + 1 -- CUSTOM
        end
        widget.setImage(string.format("%s.%s.icon", self.list, item), collectable.icon)
        widget.setImageScale(string.format("%s.%s.icon", self.list, item), 1 / scaleDown)
        count = count + 1 -- CUSTOM
      end
      widget.setText(string.format("%s.%s.index", self.list, item), collectable.order)

      self.currentCollectables[string.format("%s.%s", self.list, item)] = collectable;
    end
    widget.setText("selectLabel", string.format("%s ^%s;[%s/%s]", collection.title, collected == 0 and '#888888' or collected < count and '#BBBBBB' or '#00DD00', collected, count)) -- CUSTOM - added count
  else
    widget.setVisible("emptyLabel", true)
    widget.setText("selectLabel", "Collection")
  end
end

function createTooltip(screenPosition)
  for widgetName, collectable in pairs(self.currentCollectables) do
    if widget.inMember(widgetName, screenPosition) and self.playerCollectables[collectable.name] then
      local tooltip = config.getParameter("tooltipLayout")
      tooltip.title.value = collectable.title
      tooltip.description.value = collectable.description
      return tooltip
    end
  end
end

function selectCollection(index, data)
  populateList()
end

function selectCustomCollection(index, data)
  sb.logInfo("custom collection list click detection: actually working! FIXME")
--[[
  local listItem = widget.getListSelected(self.customList)
  if listItem then
    populateList(listItem)
  end
]]
end
