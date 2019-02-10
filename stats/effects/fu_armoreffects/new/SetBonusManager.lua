require "/scripts/util.lua"

function init()
  -- Read armor set config.
  self.armorSets = root.assetJson("/stats/effects/fu_armoreffects/new/armorsets.config")
  self.activeSet = nil
  script.setUpdateDelta(5)
end

function uninit()
end

function update()
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
