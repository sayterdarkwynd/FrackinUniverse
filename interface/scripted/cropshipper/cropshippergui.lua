function init()
  local acceptItems = config.getParameter("acceptItems")
  local sellFactor = config.getParameter("sellFactor")
  self.itemValues = {}

  for _, itemName in ipairs(acceptItems) do
    local itemConfig = root.itemConfig(itemName)
    if itemConfig then
        self.itemValues[itemName] = math.ceil((itemConfig.config.price or 0) * sellFactor)
    end
  end

end

function update(dt)
  widget.setText("lblMoney", valueOfContents())
end

function triggerShipment(widgetName, widgetData)
  world.sendEntityMessage(pane.containerEntityId(), "triggerShipment")
  local total = valueOfContents()
  if total > 0 then
    player.giveItem({name = "money", count = total})
  end
  pane.dismiss()
end

-- FU EXTRA CODE
function containsOneOf(tags, ...)
  if type(tags) == 'table' then
    for _,lookfor in ipairs({...}) do
      for _,tag in ipairs(tags) do
        if tag == lookfor then return true end
      end
    end
  else
    for _,lookfor in ipairs({...}) do
      if tags == lookfor then return true end
    end
  end
  return false
end
-- END FU EXTRA CODE

function valueOfContents()
  local value = 0
  local allItems = widget.itemGridItems("itemGrid")
  for _, item in pairs(allItems) do
-- FU EXTRA CODE replacing original value calculation
    local price = self.itemValues[item.name]
    if not price then
      -- learn as we go; useful for non-default items
      local cfg = root.itemConfig(item).config
      if cfg then
        if cfg.price and cfg.price > 0 then
          if cfg.category == 'seed' or
             cfg.category == 'food' or
             cfg.category == 'preparedFood' or
             cfg.category == 'drink' or
             (cfg.category == 'craftingMaterial' and containsOneOf(cfg.itemTags, 'textile', 'monsterdrop')) then
            self.itemValues[item.name] = math.ceil(cfg.price * config.getParameter("sellFactor",0.0))
          end
        end
      end
      if not self.itemValues[item.name] then
        self.itemValues[item.name] = 0 -- not suitable? set price to 0 to avoid another look-up
      end
      price = self.itemValues[item.name]
    end
    if price then
      value = value + price * item.count
    end
-- END FU EXTRA CODE
  end
  return value
end
