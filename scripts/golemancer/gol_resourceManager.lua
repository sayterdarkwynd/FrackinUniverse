-- Consume the resources specified in "pattern.requiredResources"
-- Returns "consuming", "allConsumed" or "cantConsume"
function consumeResources(pattern)
  local hasConsumed = false
  for _, resource in pairs(pattern.requiredResources) do
    if resource.type == "liquid" then
      hasConsumed = consumeLiquid(resource) or hasConsumed
    end
    if resource.type == "droppedItem" then
      hasConsumed = consumeDroppedItem(resource) or hasConsumed
    end
    if resource.type == "damageDone" then
      hasConsumed = consumeDamageDone(resource) or hasConsumed
    end
    if resource.type == "damageAura" then
      hasConsumed = consumeDamageAura(resource) or hasConsumed
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
	if not world.isTileProtected(self.position) then
		local liqTable = world.liquidAt(self.position)
		if (liqTable and resource) and (liqTable[1] == resource.id) and (liqTable[2] >= 0.99) then --if liqTable and liqTable[1] == resource.id and liqTable[2] >= 0.99 then
			--self.liquidRemoveVal = world.destroyLiquid(self.position)[2] or nil
			self.consumedTable[resource.name] = (self.consumedTable[resource.name] or 0) + world.destroyLiquid(self.position)[2]
			return true
		else
			return false
		end
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

-- Try to consume health, returns false if cant consume
function consumeDamageDone( resource )
  if not self.lastDmgDoneMoment then _,self.lastDmgDoneMoment = status.damageTakenSince() end
  dmgNotifications, self.lastDmgDoneMoment = status.inflictedDamageSince(self.lastDmgDoneMoment)
  if dmgNotifications then
    for _, dmgNotif in pairs(dmgNotifications) do
      self.consumedTable[resource.name] = (self.consumedTable[resource.name] or 0) + dmgNotif.damageDealt
    end
    return true
  end
  return false
end

-- Try to consume health, returns false if cant consume
function consumeDamageAura( resource )
  local targetIds = world.entityQuery(self.position, resource.range or 8, {
    withoutEntityId = entity.id(),
    includedTypes = resource.id or {"all"}
  })

  if targetIds and targetIds[1] then
    local directionTo = world.distance(world.entityPosition(targetIds[1]), self.position)
    world.spawnProjectile(
      resource.projectile or "teslaboltsmall",
      self.position,
      entity.id(),
      directionTo,
      false,
      {
        power = resource.power,
        movementSettings = { collisionEnabled = false }
      }
    )
    self.consumedTable[resource.name] = (self.consumedTable[resource.name] or 0) + resource.power
    return true
  end
  return false
end

-- Checks if all pattern resources has being consumed
function allConsumed(pattern)
  local consumed = true
  for _, resource in pairs(pattern.requiredResources) do
    consumed = consumed and self.consumedTable[resource.name] and self.consumedTable[resource.name] >= resource.amount
  end
  return consumed
end
