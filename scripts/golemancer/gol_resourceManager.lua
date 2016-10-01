-- Consume the resources specified in "pattern.requiredResources"
-- Returns "consuming", "allConsumed" or "cantConsume"
function consumeResources(pattern)
  local hasConsumed = false

  for _, resource in pairs(pattern.requiredResources) do
    if resource.type == "liquid" then
      hasConsumed = consumeLiquid(resource) or hasConsumed
    elseif resource.type == "droppedItem" then
      hasConsumed = consumeDroppedItem(resource) or hasConsumed
    end
  end

  if allConsumed(pattern) then
    return "allConsumed"
  else
    return hasConsumed and "consuming" or "cantConsume"
  end

end

-- Try to consume liquid, returns false if cant consume the liquid
function consumeLiquid( resource )
  local liqTable = world.liquidAt(self.position)
  if liqTable and liqTable[1] == resource.id and liqTable[2] >= 0.99 then
    self.consumedTable[resource.name] = (self.consumedTable[resource.name] or 0) + world.destroyLiquid(self.position)[2]
    return true
  else
    return false
  end
end

-- Try to consume liquid, returns false if cant consume the liquid
function consumeDroppedItem( resource )
  local itemtable =  world.itemDropQuery(self.position, 3.0)
  for _, itemId in pairs(itemtable) do
    if world.entityName(itemId) == resource.id then
      local itemsTaken = world.takeItemDrop(itemId)
      if itemsTaken then
        self.consumedTable[resource.name] = (self.consumedTable[resource.name] or 0) + itemsTaken.count
        return true
      end
    end
  end
  return false
end

-- Checks if all pattern resources has being consumed
function allConsumed(pattern)
  local consumed = true
  for _, resource in pairs(pattern.requiredResources) do
    consumed = consumed and self.consumedTable[resource.name] and self.consumedTable[resource.name] >= resource.ammount
  end
  return consumed
end
