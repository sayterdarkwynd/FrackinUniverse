require "/scripts/util.lua"

function init()
  -- Read armor set config.
  self.armorSets = root.assetJson("/stats/effects/fu_armoreffects/new/armorsets.config")
  self.activeSet = nil
  self.currentHead = nil
  self.currentChest = nil
  self.currentLegs = nil
  script.setUpdateDelta(5)
end

function uninit()
end

function update()
  -- Check if player's equipped armour.
  local newHead = player.equippedItem("head")
  local newChest = player.equippedItem("chest")
  local newLegs = player.equippedItem("legs")
  -- Only check set bonuses if armour has changed!
  if ((self.currentHead ~= newHead) or
      (self.currentChest ~= newChest) or
      (self.currentLegs ~= newLegs)) then
    self.currentHead = newHead
    self.currentChest = newChest
    self.currentLegs = newLegs
    -- Loop through armour sets and check for a complete set (count = 3).
    local newSet = nil
    for setStat, setEffect in pairs(self.armorSets) do
      if (status.stat(setStat) == 3) then
        newSet = setEffect
        break
      end
    end
    if (newSet ~= self.activeSet) then
      if (self.activeSet ~= nil) then
        status.clearPersistentEffects("setbonus")
      end
      if (newSet ~= nil) then
        status.addPersistentEffects("setbonus", {newSet})
      end
      self.activeSet = newSet
    end
  end
end
