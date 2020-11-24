function buildDamageTypeKillCondition(config)
  --Set up the damageType kill condition
  local damageTypeKillCondition = {
    description = config.description or root.assetJson("/quests/quests.config:objectiveDescriptions.nebDamageTypeKill"),
    damageTypeName = config.displayDamageTypeName,
    damageTypes = config.damageTypes or {},
    count = config.count or 1
  }

  --Set up the function for checking if the conditions were met
  function damageTypeKillCondition:conditionMet()
    return storage.nebDamageTypeKillCount >= self.count
  end

  --Set up the function for performing actions upon quest complete
  --These get called in addition to the default quest complete actions, and so should only contain actions relative to the objective
  function damageTypeKillCondition:onQuestComplete()
    --Nothing here!
  end

  --Set up the function for constructing the objective text
  function damageTypeKillCondition:objectiveText()
    local objective = self.description
    objective = objective:gsub("<damageType>", self.damageTypeName)
    objective = objective:gsub("<required>", self.count)
    objective = objective:gsub("<current>", storage.nebDamageTypeKillCount or 0)
    return objective
  end

  function damageTypeKillCondition:onUpdate()
    --Check for inflicted hits and add a to the count on kill
    local damageNotifications, nextStep = status.inflictedDamageSince(self.queryDamageSince or 0)
    self.queryDamageSince = nextStep

	--local damageNotificationInfo = sb.printJson(damageNotifications, 1)
	--sb.logInfo(damageNotificationInfo)

    for _, notification in ipairs(damageNotifications) do
	  if notification.targetEntityId then
	    if notification.hitType == "Kill" and world.entityCanDamage(notification.targetEntityId, player.id()) then
		  for _, damageType in pairs(self.damageTypes) do
		    if damageType == notification.damageSourceKind then
			  storage.nebDamageTypeKillCount = storage.nebDamageTypeKillCount + 1
			end
		  end
	    end
	  end
    end
  end

  --Remember how many messages we have already received
  storage.nebDamageTypeKillCount = storage.nebDamageTypeKillCount or 0


  --sb.logInfo("======================== TEST ========================")
  --sb.logInfo("SELF =")
  --sb.logInfo(sb.printJson(self, 1))
  --sb.logInfo("======================== TEST ========================")

  return damageTypeKillCondition
end
