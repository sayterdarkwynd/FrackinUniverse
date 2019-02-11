require "/scripts/util.lua"

--[[
    NOTE: In order to minimise the amount of looping through armour sets that
    is done here, we will assume that a set is complete if its "count" stat is
    3 and all others are zero. Therefore, if we encounter a "count" stat which
    is 1 or 2, this indicates the player is mixing different sets - and
    therefore must not wearing any full set. The practical use of this is that
    once we detect one nonzero "count" stat, we can check it first on
    subsequent updates without worrying if a different set is active.
]]--

function init()
  -- Read armor set config.
  self.armorSets = root.assetJson("/stats/effects/fu_armoreffects/new/armorsets.config")
  self.activeSet = nil -- Currently active set bonus
  self.lastStat = nil -- Last detected "count" stat
  script.setUpdateDelta(100) -- This seems to translate to  ~1.6 seconds (YMMV)
end

function uninit()
end

function update()
  local newSet = nil
  -- Check the "count" stat found last update() before looping over others.
  if (self.lastStat ~= nil and status.stat(self.lastStat) > 0) then
    if (status.stat(self.lastStat) == 3) then
      newSet = self.armorSets[self.lastStat]
    else
      newSet = nil
    end
  else
    for setStat, setEffect in pairs(self.armorSets) do
      if (status.stat(setStat) > 0) then
        self.lastStat = setStat
        if (status.stat(setStat) == 3) then
          newSet = setEffect
        else
          newSet = nil
        end
        break
      end
    end
  end
  -- If the active armour set has changed, then apply/remove set bonuses.
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
