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
  -- This line just removes any of the old persistent set bonus effects.
  status.clearPersistentEffects("setbonus")

  script.setUpdateDelta(100) -- This seems to translate to  ~1.6 seconds (YMMV) --1.4 (Khe)
end

function uninit()
	--status.addEphemeralEffect("fusetbonusmanagercleanup")
  --[[
      NOTE: If the player changes their equipped armour pieces one by one,
      will be nothing to do here as the update() script will have already
      removed any set bonuses. However, it is possible for the player to change
      all of their equipment at once using a mannequin. In this case, this
      script will be uninitialised before it can remove the set bonus.

      It would be ideal to call status.removeEphemeralEffect() to remove any
      remaining set bonuses here as a fallback case, but it seems that
      attempting to do so causes the Lua script to enter a recursion loop and
      crash the game. Using ephemeral effects here (instead of persistent ones)
      means that this is not a critical problem as the set bonus effect will
      expire on its own.

      But seriously, that's super weird. --wannas, Jul 2019
  ]]--
end

function update(dt)
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
  -- Apply/remove set bonuses depending on the currently worn set.
  if (newSet ~= nil) then
    if (self.activeSet ~= newset) then
      -- This is possible if sets were swapped all at once (via mannequin).
      status.removeEphemeralEffect(self.activeSet)
    end
    status.addEphemeralEffect(newSet, dt*1.1)
  elseif (self.activeSet ~= nil) then
    status.removeEphemeralEffect(self.activeSet)
  end
  self.activeSet = newSet
end
