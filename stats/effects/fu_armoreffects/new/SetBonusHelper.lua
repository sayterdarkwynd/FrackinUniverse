require "/scripts/util.lua"

SetBonusHelper = {}

--============================= CLASS DEFINITION ============================--

function SetBonusHelper.new(self, child)
  child = child or {}
  setmetatable(child, self)
  child.parent = self
  self.__index = self
  return child
end

--============================== INIT AND UNINIT =============================--

function SetBonusHelper.init(self)
  -- Set status effect(s)
  self.statusEffects = config.getParameter("statusEffects")
  -- Armor effects
  self.armorBonuses = config.getParameter("armorBonuses")
  self.armorMovementModifiers = config.getParameter("armorMovementModifiers")
  -- Weapon effects
  self.weaponBonuses = config.getParameter("weaponBonuses")
  --[[ NOTE: weaponBonuses should be an array with three keys:
      * "normal": The basic bonuses to apply with a 1-handed weapon.
      * "dual": Additional bonuses to add when dual-wielding 1-handed weapons.
      * "twohand": Additional bonuses to apply when wielding a 2-handed wewapon.
      The "normal" key is mandatory. If "dual" or "twohand" are omitted, no
      additional bonuses will be applied.
  ]]--
  -- Biome effects
  self.biomeBonuses = config.getParameter("biomeBonuses")
  -- Equipped armor checks
  self.armorSetStat = config.getParameter("armorSetStat")
  self.setBonusActive = false
  -- Equipped weapon checks
  self.weaponTags = config.getParameter("weaponTags")
  self.offhandTags = config.getParameter("offhandTags")
  self.currentPrimary = nil
  self.currentAlt = nil
  self.bonusWeaponCount = 0 -- 0, 1 or 2
  self.bonusTwoHanded = false
  -- Bonus biome checks
  self.currentBiome = nil
  self.biomeTags = config.getParameter("biomeTags")
  -- Buff groups
  self.armorBonusGroup = effect.addStatModifierGroup({})
  self.weaponBonusGroup = effect.addStatModifierGroup({})
  self.biomeBonusGroup = effect.addStatModifierGroup({})

  script.setUpdateDelta(5)
end

function SetBonusHelper.uninit(self)
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function SetBonusHelper.isWearingSet(self)
  -- Every armor set consists of 3 pieces. See if the set stat equals 3.
  local count = status.stat(self.armorSetStat)
  return (count == 3)
end

-- Returns true if the weapon count has changed, and false otherwise.
function SetBonusHelper.updateBonusWeaponCount(self)
  if (self.weaponTags == nil or #(self.weaponTags) == 0) then
    return false
  end
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

function SetBonusHelper.inBonusBiome(self)
  local tags = self.biomeTags
  if (tags == nil or #tags == 0) then
    return false
  end
  for _, tag in pairs(tags) do
    if (self.currentBiome == tag) then
      return true
    end
  end
  return false
end

--========================== BONUS EFFECT FUNCTIONS ==========================--

function SetBonusHelper.getBonusGroupFromTable(self, name, table)
  if (table.amount ~= nil) then
    return {stat = name, amount = table.amount}
  elseif (table.baseMultiplier ~= nil) then
    return {stat = name, baseMultiplier = table.baseMultiplier}
  elseif (table.effectiveMultiplier ~= nil) then
    return {stat = name, effectiveMultiplier = table.effectiveMultiplier}
  else
    -- Default to 'amount = 1'.
    return {stat = name, amount = 1}
  end
end

function SetBonusHelper.applyArmorBonuses(self)
  status.addPersistentEffects("setbonus", self.statusEffects)
  local newGroup = {}
  local i = 1
  for stat, bonus in pairs(self.armorBonuses) do
    local next = self:getBonusGroupFromTable(tostring(stat), bonus)
    if (next ~= false) then
      newGroup[i] = next
      i = i + 1
    end
  end
  -- Update armor bonus modifier group.
  effect.setStatModifierGroup(self.armorBonusGroup, newGroup)
end

function SetBonusHelper.removeArmorBonuses(self)
  status.clearPersistentEffects("setbonus")
  effect.removeStatModifierGroup(self.armorBonusGroup)
  self.armorBonusGroup = effect.addStatModifierGroup({})
end

function SetBonusHelper.applyArmorMovementModifiers(self)
  local modifiers = self.armorMovementModifiers
  if (modifiers ~= nil and (modifiers.speed ~= nil or modifiers.jump ~= nil)) then
    mcontroller.controlModifiers({
      speedModifier = modifiers.speed,
      airJumpModifier = modifiers.jump
    })
  end
end

function SetBonusHelper.updateWeaponBonuses(self)
  if (self.bonusWeaponCount > 0) then
    -- 1. Add normal weapon bonuses.
    local newGroup = {}
    local i = 1
    for stat, bonus in pairs(self.weaponBonuses.normal) do
      local next = self:getBonusGroupFromTable(tostring(stat), bonus)
      if (next ~= false) then
        newGroup[i] = next
        i = i + 1
      end
    end
    -- 2. Add dual-wielding weapon bonuses, if applicable.
    if ((self.bonusWeaponCount == 2) and (self.weaponBonuses.dual ~= nil)) then
      for stat, bonus in pairs(self.weaponBonuses.dual) do
        local next = self:getBonusGroupFromTable(tostring(stat), bonus)
        if (next ~= false) then
          newGroup[i] = next
          i = i + 1
        end
      end
    end
    -- 3. Add two-handed weapon bonuses, if applicable.
    if ((self.bonusWeaponCount == 1) and self.bonusTwoHanded and (self.weaponBonuses.twohand ~= nil)) then
      for stat, bonus in pairs(self.weaponBonuses.twohand) do
        local next = self:getBonusGroupFromTable(tostring(stat), bonus)
        if (next ~= false) then
          newGroup[i] = next
          i = i + 1
        end
      end
    end
    -- Update weapon bonus modifier group.
    effect.setStatModifierGroup(self.weaponBonusGroup, newGroup)
  else
    self:removeWeaponBonuses()
    return
  end
end

function SetBonusHelper.removeWeaponBonuses(self)
  effect.removeStatModifierGroup(self.weaponBonusGroup)
  self.weaponBonusGroup = effect.addStatModifierGroup({})
end

function SetBonusHelper.updateBiomeBonuses(self)
  if (self:inBonusBiome() == true) then
    local newGroup = {}
    local i = 1
    for stat, bonus in pairs(self.biomeBonuses) do
      local next = self:getBonusGroupFromTable(tostring(stat), bonus)
      if (next ~= false) then
        newGroup[i] = next
        i = i + 1
      end
    end
    -- Update biome bonus modifier group.
    effect.setStatModifierGroup(self.biomeBonusGroup, newGroup)
  else
    self:removeBiomeBonuses()
  end
end

function SetBonusHelper.removeBiomeBonuses(self)
  effect.removeStatModifierGroup(self.biomeBonusGroup)
  self.biomeBonusGroup = effect.addStatModifierGroup({})
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function SetBonusHelper.update(self)
  -- Add/remove set bonus effects if the player has put on or taken off the set.
  local active = self:isWearingSet()
  if (self.setBonusActive ~= active) then
    self.setBonusActive = active
    if (active) then
      self:applyArmorBonuses()
      -- Force weapon and biome checks and updates on set bonus activation.
      self:updateBonusWeaponCount()
      self:updateWeaponBonuses()
      self.currentBiome = world.type()
      self:updateBiomeBonuses()
    else
      self:removeWeaponBonuses()
      self:removeArmorBonuses()
      self:removeBiomeBonuses()
    end
  end
  if (active) then
    -- Apply any movement modifiers from armor set.
    self:applyArmorMovementModifiers()
    -- Update bonus weapon effects if the player's bonus weapon count has changed.
    local changed = self:updateBonusWeaponCount()
    if (changed) then
      self:updateWeaponBonuses()
    end
    -- Update biome bonus effects if the current world type has changed.
    local newBiome = world.type()
    if (self.currentBiome ~= newBiome) then
      self.currentBiome = newBiome
      self:updateBiomeBonuses()
    end
  end
end
