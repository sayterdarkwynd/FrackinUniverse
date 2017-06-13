require "/scripts/util.lua"

function buildTradingConfig()
  -- Build list of all possible items
  local level = npc.level()
  local items = {}
  self.merchantPools = root.assetJson(config.getParameter("merchant.poolsFile", "/npcs/merchantpools.config"))
  for _, category in pairs(getCategories()) do
    local levelSets = self.merchantPools[category]
    if levelSets ~= nil then
      -- Find the highest available level within the category
      local highestLevel, highestLevelSet = -1, nil
      for _, levelSet in pairs(levelSets) do
        if level >= levelSet[1] and levelSet[1] > highestLevel then
          highestLevel, highestLevelSet = levelSet[1], levelSet[2]
        end
      end

      if highestLevelSet ~= nil then
        for _, item in pairs(highestLevelSet) do
          if item.item.parameters then item.item.parameters.level = npc.level() end
          table.insert(items, item)
        end
      end
    end
  end

  -- Reset the PRNG so the same seed always generates the same set of items.
  -- The uint64_t seed can get truncated when converted to a lua double, but
  -- it will at least provide a deterministic seed, even if the full range of
  -- input seeds can't be used
  local seed
  if config.getParameter("merchant.rotateStock", false) then
    seed = math.floor(os.time() / config.getParameter("merchant.rotationTime"))
  else
    seed = tonumber(npc.seed())
  end
  math.randomseed(seed)

  -- Shuffle the list
  for i = #items, 2, -1 do
    local j = math.random(i)
    items[i], items[j] = items[j], items[i]
  end

  local selectedItems, skippedItems = {}, {}
  local numItems = config.getParameter("merchant.numItems")
  for _, item in pairs(items) do
    if item.rarity == nil or math.random() < item.rarity then
      table.insert(selectedItems, item)

      if #selectedItems == numItems then
        break
      end
    else
      table.insert(skippedItems, item)
    end
  end

  -- May need to dip into the rare items to get enough
  for i = 1, math.min(#skippedItems, numItems - #selectedItems) do
    table.insert(selectedItems, skippedItems[i])
  end

  -- Add the items that have been earned via completing quests for the merchant
  for _,item in pairs(storage.extraMerchantItems or {}) do
    table.insert(selectedItems, {item = item})
  end

  -- Generate all randomized items with a consistent seed and level
  local level = npc.level()
  for _, item in pairs(selectedItems) do
    if item.useSeed then
      item.item.parameters = item.item.parameters or {}
      item.item.parameters.seed = item.item.parameters.seed or math.random(4294967295)
    end
    local newItem = root.createItem(item.item, level)
    item.item = newItem
  end

  -- If this is the first time, pick a randomized buyFactor and sellFactor
  if storage.buyFactor == nil then
    storage.buyFactor = util.randomInRange(config.getParameter("merchant.buyFactorRange"))
  end
  if storage.sellFactor == nil then
    storage.sellFactor = util.randomInRange(config.getParameter("merchant.sellFactorRange"))
  end

  -- Now build the actual trading config
  local tradingConfig = {
    config = "/interface/windowconfig/merchant.config",
    sellFactor = storage.sellFactor,
    buyFactor = storage.buyFactor,
    items = selectedItems,
    paneLayoutOverride = config.getParameter("merchant.paneLayoutOverride", nil)
  }

  -- Reset RNG
  math.randomseed(os.time())

  return tradingConfig
end

-- param item
function addTradableItem(args, board)
  if args.item == nil then return false end
  if not itemDescriptor then return false end
  if type(itemDescriptor) == "string" then
    args.item = { name = itemDescriptor }
  end

  storage.extraMerchantItems = storage.extraMerchantItems or {}
  for _,item in pairs(storage.extraMerchantItems) do
    if compare(item, args.item) then
      return true
    end
  end
  table.insert(storage.extraMerchantItems, itemDescriptor)
  self.tradingConfig = buildTradingConfig()

  return true
end

function countExtraMerchantItems()
  return #(storage.extraMerchantItems or {})
end

function sellsItem(itemName)
  if not self.tradingConfig then
    self.tradingConfig = buildTradingConfig()
  end
  for _,item in pairs(self.tradingConfig.items) do
    if item.item == itemName or item.item.name == itemName then
      return true
    end
  end
  return false
end

function getCategories()
  local species = npc.species()
  -- sb.logInfo("merchant.lua::getCategories: species is %s, npcType is %s, merc.cat.override is %s, m.c.default is %s", species, npc.npcType(), config.getParameter("merchant.categories.override"), config.getParameter("merchant.categories.default"))
  if config.getParameter("merchant.categories.override") then
    return config.getParameter("merchant.categories.override")
  elseif config.getParameter("merchant.categories."..species) then
    return config.getParameter("merchant.categories."..species)
  else
    return config.getParameter("merchant.categories.default") or { oops = "basicmerchant" }
  end
end

function enableTrading(args, board)
  if not self.tradingConfig then
    self.tradingConfig = buildTradingConfig()
  end
  self.tradingEnabled = true
  return true
end
