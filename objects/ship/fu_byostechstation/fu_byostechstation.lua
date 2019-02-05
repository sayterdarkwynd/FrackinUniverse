function init()
  --Instantly spawn the pet when first created
  storage.spawnTimer = storage.spawnTimer and 0.5 or 0
  storage.petParams = storage.petParams or {}

  self.monsterType = config.getParameter("shipPetType", "petcat")
  
  --Purcahasable Pets Fix
  if self.monsterType == "slimecritter" and root.itemConfig("pethouseSlime") then
    self.monsterType = "petslime"
  end
  
  self.spawnOffset = config.getParameter("spawnOffset", {0, 2})

  message.setHandler("activateShip", function()
    animator.playSound("shipUpgrade")
    self.dialog = config.getParameter("dialog.wakeUp")
    self.dialogTimer = 0.0
    self.dialogInterval = 5.0
    self.drawMoreIndicator = true
    object.setOfferedQuests({})
  end)

  message.setHandler("wakePlayer", function()
    self.dialog = config.getParameter("dialog.wakePlayer")
    self.dialogTimer = 0.0
    self.dialogInterval = 14.0
    self.drawMoreIndicator = false
    object.setOfferedQuests({})
  end)
end

function onInteraction()
  if self.dialogTimer then
    sayNext()
    return nil
  else
    return config.getParameter("interactAction")
  end
end

function hasPet()
  return self.petId ~= nil
end

function setPet(entityId, params)
  if self.petId == nil or self.petId == entityId then
    self.petId = entityId
    storage.petParams = params
  else
    return false
  end
end

function sayNext()
  if self.dialog and #self.dialog > 0 then
    if #self.dialog > 0 then
      local options = {
        drawMoreIndicator = self.drawMoreIndicator
      }
      self.dialogTimer = self.dialogInterval
      if #self.dialog == 1 then
        options.drawMoreIndicator = false
        self.dialogTimer = 0.0
      end

      object.sayPortrait(self.dialog[1][1], self.dialog[1][2], nil, options)
      table.remove(self.dialog, 1)

      return true
    end
  else
    self.dialog = nil
    return false
  end
end

function update(dt)
  if self.petId and not world.entityExists(self.petId) then
    self.petId = nil
  end

  if storage.spawnTimer < 0 and self.petId == nil then
    storage.petParams.level = 1
    self.petId = world.spawnMonster(self.monsterType, object.toAbsolutePosition(self.spawnOffset), storage.petParams)
    world.callScriptedEntity(self.petId, "setAnchor", entity.id())
    storage.spawnTimer = 0.5
  else
    storage.spawnTimer = storage.spawnTimer - dt
  end

  if self.dialogTimer then
    self.dialogTimer = math.max(self.dialogTimer - dt, 0.0)
    if self.dialogTimer == 0 and not sayNext() then
      self.dialogTimer = nil
    end
  end
  
  if self.dialogTimer == nil then
    object.setOfferedQuests(config.getParameter("offeredQuests"))
  end
end
