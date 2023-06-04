function init()
  cloningPrep()
  storage.bannedFoliage = config.getParameter("bannedFoliage")
  storage.bannedStems = config.getParameter("bannedStems")
end

function cloningPrep()
  if self.hasPrepped == false then
    storage.heldItems = world.containerItems(entity.id())
    self.pause = false
    self.hasPrepped = true
  end
end

function containerCallback()
  local items = world.containerItems(entity.id())

  if items[1]~=null and items[2]~=null and
     items[1].name == "sapling" and items[2].name == "sapling" then

    local leafsample = items[2]
    local stemsample = items[1]

    if checkBanlist(leafsample, stemsample) then
      local biomatteramount = leafsample.count + stemsample.count
      stemsample.parameters["foliageHueShift"] = leafsample.parameters["foliageHueShift"]
      stemsample.parameters["foliageName"] = leafsample.parameters["foliageName"]
      world.containerTakeAll(entity.id())
      stemsample.count = biomatteramount
      world.containerPutItemsAt(entity.id(),stemsample,1)
    end
  end
end

function checkBanlist(leafsample, stemsample)
  local leaf = leafsample.parameters["foliageName"]
  local stem = stemsample.parameters["stemName"]

  for _, bannedLeaf in ipairs(storage.bannedFoliage) do
    if leaf == bannedLeaf then
      return false
    end
  end
  for _, bannedStem in ipairs(storage.bannedStems) do
    if stem == bannedStem then
      return false
    end
  end
  return true
end

function die()
end
