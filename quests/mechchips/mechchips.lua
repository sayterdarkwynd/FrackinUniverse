function init()
  --chip code
  message.setHandler("setMechExpansionSlotItem", function(_, _, value)
	  storage.expansionSlotItem = value
  end)

  message.setHandler("getMechExpansionSlotItem", function()
	  return storage.expansionSlotItem
  end)

  message.setHandler("setMechUpgradeItem1", function(_, _, value)
	  storage.upgradeItem1 = value
  end)

  message.setHandler("getMechUpgradeItem1", function()
	  return storage.upgradeItem1
  end)

  message.setHandler("setMechUpgradeItem2", function(_, _, value)
	  storage.upgradeItem2 = value
  end)

  message.setHandler("getMechUpgradeItem2", function()
	  return storage.upgradeItem2
  end)

  message.setHandler("setMechUpgradeItem3", function(_, _, value)
	  storage.upgradeItem3 = value
  end)

  message.setHandler("getMechUpgradeItem3", function()
	  return storage.upgradeItem3
  end)

  message.setHandler("getMechUpgradeItems", function()
	  local chips = {}
    chips.chip1 = storage.upgradeItem1
    chips.chip2 = storage.upgradeItem2
    chips.chip3 = storage.upgradeItem3
    chips.expansion = storage.expansionSlotItem
    return chips
  end)

  message.setHandler("setMechUpgradeItems", function(_, _, value)
	  storage.upgradeItem1 = value.chip1
    storage.upgradeItem2 = value.chip2
    storage.upgradeItem3 = value.chip3
    storage.expansionSlotItem = value.expansion
  end)
  --end


end

function update(dt)

end
