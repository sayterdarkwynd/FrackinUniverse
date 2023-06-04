require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/achievements.lua"

function init()
  self.initialising=true

  self.fossilList = config.getParameter("fossilList")
  self.isComplete = config.getParameter("fossilComplete")
  self.slotCount = config.getParameter("slotCount")

  --self.fossilSetName is the name of the current fossil set
  --sb.logInfo("fossilDisplay Init:  fossilList=%s complete=%s",self.fossilList,self.isComplete)

  self.fossilSetName = nil

  updateDisplay()
  self.initialising=false
end

-----------------------------------------------------

function containerCallback()
  if (self.isComplete~=true) then
    --sb.logInfo("Contents changed")
    self.needsUpdate=true
  end
end

-----------------------------------------------------

function update(dt)
  if (self.needsUpdate) then
    --sb.logInfo("update")

    santiseContents()
    sortIntoCorrectSlots()
    updateDisplay()
    self.needsUpdate=false
  end
end

-----------------------------------------------------

function santiseContents()
  for i=1,world.containerSize(entity.id()) do
    local item = world.containerItemAt(entity.id(), i-1) --container slots are zero indexed, hence the -1

    if (item) then
      local isFossil=root.itemHasTag(item.name, "fossil")
      --sb.logInfo("Checking Object=%s",item.name)

      if (isFossil) then
        local fossilSetName = root.itemConfig(item).config.fossilSetName
        local fossilSetCount = root.itemConfig(item).config.setCount

        if self.fossilSetName then
          if self.fossilSetName~=fossilSetName then
            ejectItemFromSlot(i)
          end
        else
          if self.slotCount==fossilSetCount then
            self.fossilSetName=fossilSetName
          else
            ejectItemFromSlot(i)
          end
        end
      else
        ejectItemFromSlot(i)
      end
    end
  end
end

-----------------------------------------------------

function ejectItemFromSlot(slotIndex)
  local item = world.containerTakeAt(entity.id(), slotIndex-1)  --container slots are zero indexed, hence the -1

  if item then
    --sb.logInfo("Ejecting Object=%s",item.name)

    world.spawnItem(item.name, object.position(), item.count, item.parameters)
  end
end

-----------------------------------------------------
function sortIntoCorrectSlots()

  self.fossilList= {}
  local count=0

  for i=1,world.containerSize(entity.id()) do
    local fossil = world.containerItemAt(entity.id(), i-1) --container slots are zero indexed, hence the -1

    if (fossil) then
      --sb.logInfo("Sorting Object=%s",fossil.name)

      local setIndex=root.itemConfig(fossil).config.setIndex

      if (setIndex~=i) then
        local item = world.containerTakeAt(entity.id(), i-1)  --container slots are zero indexed, hence the -1
        world.containerPutItemsAt(entity.id(), item, setIndex-1)
      end

      self.fossilList[setIndex]=fossil
      count=count+1
    end
  end

  if (count==0) then
    self.fossilList=nil
    self.fossilSetName=nil
  end


end
-----------------------------------------------------
function updateDisplay()
  local count=0
  local setCount=0

  for i=1,self.slotCount do
    local tagName=string.format("fossil%s",i)


    if (self.fossilList and self.fossilList[i]) then

      local fossil = self.fossilList[i]

      local displayImage=root.itemConfig(fossil).config.displayImage
      animator.setGlobalTag(tagName, displayImage)

      --sb.logInfo("Displaying %s in slot %s",displayImage,tagName)

      local transformName=string.format("fossil%stransform",i)
      if (animator.hasTransformationGroup(transformName)) then
        local displayOffset=root.itemConfig(fossil).config.displayoffset
        animator.resetTransformationGroup(transformName)
        animator.translateTransformationGroup(transformName,displayOffset)
      end

      setCount=root.itemConfig(fossil).config.setCount
      count=count+1
    else
      animator.setGlobalTag(tagName, "")
    end
  end

  if (count==setCount and count>0) then
    setFossilComplete()
  else
    if (count==0) then
      self.fossilList=nil
      self.fossilSetName=nil
    end
  end
end

-----------------------------------------------------

function setFossilComplete()
  --sb.logInfo("Completed fossil")
  self.isComplete=true

  object.setInteractive(false)

  object.setConfigParameter("fossilComplete",self.isComplete)
  object.setConfigParameter("fossilList",self.fossilList)

  animator.setAnimationState("displayStand", "completeSet")

  local firstFossil = self.fossilList[1]
  local firstFossilConfig = root.itemConfig(firstFossil).config
  local completeDescription = firstFossilConfig.completeSetDescriptions
  local fossilSetName = firstFossilConfig.fossilSetName

  --copy over all the race descriptions first
  local raceDescriptorKeyList={
      "apexDescription", "avianDescription", "floranDescription", "glitchDescription",
      "humanDescription", "hylotlDescription", "novakidDescription"}
  for i=1,#raceDescriptorKeyList do
    local key=raceDescriptorKeyList[i]
    object.setConfigParameter(key, completeDescription.description)
  end

  object.setConfigParameter("inventoryIcon", root.itemConfig(firstFossil).config.completeFossilIcon)

  --replace any descriptions with those in the fossil list.
  for k, v in pairs(completeDescription or {}) do
    object.setConfigParameter(k, v)
  end


  if (self.initialising==false) then

    --delete one of each type and spit the remainder
    for i=1,world.containerSize(entity.id()) do
      local item = world.containerItemAt(entity.id(), i-1)  --container slots are zero indexed, hence the -1

      if (item.count>1) then
        --spawn items, less one into the world.
        world.spawnItem(item.name, object.position(), item.count-1, item.parameters)
      end

      --consume items in slot.
      world.containerConsumeAt(entity.id(),i-1,item.count)

    end

    animator.playSound("fanfare")
    animator.burstParticleEmitter("completed")

    local owner = config.getParameter("owner")
    if owner then
      recordEvent(owner, "restoreFossil", {
          fossilSetName = fossilSetName,
          displayObjectName = object.name()
        })

      local setCollectables = firstFossilConfig.setCollectables
      if setCollectables then
        object.setConfigParameter("collectablesOnPickup", setCollectables)
        for collection,collectable in pairs(setCollectables) do
          world.sendEntityMessage(owner, "addCollectable", collection, collectable)
        end
      end
    end
  end
end

-----------------------------------------------------
