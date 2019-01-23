require "/scripts/util.lua"

fuSetBonusBase = {}

--============================= CLASS DEFINITION ============================--

function fuSetBonusBase.new(self, child)
  child = child or {}
  setmetatable(child, self)
  child.parent = self
  self.__index = self
  return child
end

--============================== INIT AND UNINIT =============================--

function fuSetBonusBase.init(self, config_file)
  -- Armor Set Configuration --
  self.effectConfig = root.assetJson(config_file)["effectConfig"]
  -- Set status effect(s)
  self.statusEffects = self.effectConfig.statusEffects
  -- Armor and weapon effects
  self.armorBonuses = self.effectConfig.armorBonuses
  self.armorMovementModifiers = self.effectConfig.armorMovementModifiers
  self.weaponBonuses = self.effectConfig.weaponBonuses
  --[[ NOTE: weaponBonuses should be an array with three keys:
      * "normal": The basic bonuses to apply with a 1-handed weapon.
      * "dual": Additional bonuses to add when dual-wielding 1-handed weapons.
      * "twohand": Additional bonuses to apply when wielding a 2-handed wewapon.
      The "normal" key is mandatory. If "dual" or "twohand" are omitted, no
      additional bonuses will be applied.
  ]]--
  -- Buff groups
  self.armorBonusGroup = effect.addStatModifierGroup({})
  self.weaponBonusGroup = effect.addStatModifierGroup({})
  -- Equipped armor checks
  self.armorSetStat = self.effectConfig.armorSetStat
  self.setBonusActive = false
  -- Equipped weapon checks
  self.weaponTags = self.effectConfig.weaponTags
  self.currentPrimary = nil
  self.currentAlt = nil
  self.bonusWeaponCount = 0 -- 0, 1 or 2
  self.bonusTwoHanded = false

  script.setUpdateDelta(5)
end

function fuSetBonusBase.uninit(self)
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function fuSetBonusBase.isWearingSet(self)
  -- Every armor set consists of 3 pieces. See if the set stat equals 3.
  local count = status.stat(self.armorSetStat)
  return (count == 3)
end

-- Returns true if the weapon count has changed, and false otherwise.
function fuSetBonusBase.updateBonusWeaponCount(self)
  local newPrimary = world.entityHandItem(entity.id(), "primary")
  local newAlt = world.entityHandItem(entity.id(), "alt")
  -- Check if the player's equipped items have changed. Exit if they haven't.
  if ((self.currentPrimary == newPrimary) and (self.currentAlt == newAlt)) then
    return false
  end
  self.currentPrimary = newPrimary
  self.currentAlt = newAlt
  -- Determine whether the primary and alt items have the correct tags.
  local primaryTag = 0
  local altTag = 0
  for _, tag in pairs(self.weaponTags) do
    if ((self.currentPrimary ~= nil) and root.itemHasTag(self.currentPrimary, tag)) then
      primaryTag = 1
    end
    if ((self.currentAlt ~= nil) and root.itemHasTag(self.currentAlt, tag)) then
      altTag = 1
    end
  end
  -- Update bonus weapon flags and determine if they have changed.
  local changed = false
  local count = primaryTag + altTag
  if (self.bonusWeaponCount ~= count) then
    self.bonusWeaponCount = count
    changed = true
  end
  local desc = world.entityHandItemDescriptor(entity.id(), "primary")
  local twohanded = (desc ~= nil and root.itemConfig(desc).config.twoHanded) or false
  if (self.bonusTwoHanded ~= twohanded) then
    self.bonusTwoHanded = twohanded
    changed = true
  end
  return changed
end

--========================== BONUS EFFECT FUNCTIONS ==========================--

function fuSetBonusBase.applyArmorBonuses(self)
  status.addPersistentEffects("setbonus", self.statusEffects)
  local newGroup = {}
  local i = 1
  for bStat, bAmount in pairs(self.armorBonuses) do
    statName = tostring(bStat)
    newGroup[i] = {stat = statName, amount = bAmount}
    i = i + 1
  end
  -- Update armor bonus modifier group.
  effect.setStatModifierGroup(self.armorBonusGroup, newGroup)
end

function fuSetBonusBase.removeArmorBonuses(self)
  status.clearPersistentEffects("setbonus")
  effect.removeStatModifierGroup(self.armorBonusGroup)
  self.armorBonusGroup = effect.addStatModifierGroup({})
end

function fuSetBonusBase.applyArmorMovementModifiers(self)
  local modifiers = self.armorMovementModifiers
  if (modifiers ~= nil and (modifiers.speed ~= nil or modifiers.jump ~= nil)) then
    mcontroller.controlModifiers({
      speedModifier = modifiers.speed,
      airJumpModifier = modifiers.jump
    })
  end
end

function fuSetBonusBase.updateWeaponBonuses(self)
  if (self.bonusWeaponCount > 0) then
    -- 1. Add normal weapon bonuses.
    local newStats = {}
    local newMultipliers = {}
    for stat, bonus in pairs(self.weaponBonuses.normal) do
      local statName = tostring(stat)
      if (bonus.multiplier == true) then
        newMultipliers[statName] = bonus.amount
      else
        newStats[statName] = bonus.amount
      end
    end
    -- 2. Add dual-wielding weapon bonuses, if applicable.
    if ((self.bonusWeaponCount == 2) and (self.weaponBonuses.dual ~= nil)) then
      for stat, bonus in pairs(self.weaponBonuses.dual) do
        local statName = tostring(stat)
        -- Add together with existing stats of the same type.
        if (bonus.multiplier == true) then
          if (newMultipliers[statName] ~= nil) then
            newMultipliers[statName] = newMultipliers[statName] + bonus.amount
          else
            newMultipliers[statName] = bonus.amount
          end
        else
          if (newStats[statName] ~= nil) then
            newStats[statName] = newStats[statName] + bonus.amount
          else
            newStats[statName] = bonus.amount
          end
        end
      end
    end
    -- 3. Add two-handed weapon bonuses, if applicable.
    if ((self.bonusWeaponCount == 1) and self.bonusTwoHanded and (self.weaponBonuses.twohand ~= nil)) then
      for stat, bonus in pairs(self.weaponBonuses.twohand) do
        local statName = tostring(stat)
        -- Add together with existing stats of the same type.
        if (bonus.multiplier == true) then
          if (newMultipliers[statName] ~= nil) then
            newMultipliers[statName] = newMultipliers[statName] + bonus.amount
          else
            newMultipliers[statName] = bonus.amount
          end
        else
          if (newStats[statName] ~= nil) then
            newStats[statName] = newStats[statName] + bonus.amount
          else
            newStats[statName] = bonus.amount
          end
        end
      end
    end
    -- Format the total boosts into a statModifierGroup.
    local newGroup = {}
    local i = 1
    for statName, statAmt in pairs(newStats) do
      newGroup[i] = {stat = statName, amount = statAmt}
      i = i + 1
    end
    for statName, statMult in pairs(newMultipliers) do
      newGroup[i] = {stat = statName, effectiveMultiplier = statMult}
      i = i + 1
    end
    -- Update armor bonus modifier group.
    effect.setStatModifierGroup(self.weaponBonusGroup, newGroup)
  else
    self:removeWeaponBonuses()
    return
  end
end

function fuSetBonusBase.removeWeaponBonuses(self)
  effect.removeStatModifierGroup(self.weaponBonusGroup)
  self.weaponBonusGroup = effect.addStatModifierGroup({})
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function fuSetBonusBase.update(self)
  -- Add/remove set bonus effects if the player has put on or taken off the set.
  local active = self:isWearingSet()
  if (self.setBonusActive ~= active) then
    self.setBonusActive = active
    if (active) then
      self:applyArmorBonuses()
      self:updateWeaponBonuses()
    else
      self:removeWeaponBonuses()
      self:removeArmorBonuses()
    end
  end
  if (active) then
    -- Apply any movement modifiers from armor set.
    self:applyArmorMovementModifiers()
    -- Update bonus weapon effects if the player's bonus weapon count has changed.
    changed = self:updateBonusWeaponCount()
    if (changed) then
      self:updateWeaponBonuses()
    end
  end
end
