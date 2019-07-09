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
  -- Armor effects
  self.armorBonuses = config.getParameter("armorBonuses")
  self.armorMovementModifiers = config.getParameter("armorMovementModifiers")
  self.armorEphemeralEffects = config.getParameter("armorEphemeralEffects")
  -- Weapon effects
  self.weaponBonuses = config.getParameter("weaponBonuses")
--[[ Example weaponBonuses:
"weaponBonuses" : [
  { // +20 HP with (sword or mace) + shield
    "type" : "dual",
    "tags" : ["shortsword", "longsword", "mace"],
    "altTags" : ["shield"],
    "stats" : {
      "maxHealth" : {"baseMultiplier" : 1.20}
    }
  },
  { // +5% crit chance while using two-handed shotguns
    "type" : "twohand",
    "tags" : ["shotgun"],
    "stats" : {
      "critChance" : {"amount" : 5}
    }
  },
  { // +10% dmg while using any dagger/pistol
    "type" : "either",
    "tags" : ["dagger", "pistol"],
    "stats" : {
      "powerMultiplier" : {"effectiveMultiplier" : 1.10}
    }
  }
]
]]--
  -- Biome effects
  self.biomeBonuses = config.getParameter("biomeBonuses")
  self.biomeMovementModifiers = config.getParameter("biomeMovementModifiers")
  -- Equipped weapon checks (weapon tags are integrated with bonuses)
  self.currentPrimary = nil
  self.currentAlt = nil
  -- Bonus biome checks
  self.currentBiome = nil
  self.biomeTags = config.getParameter("biomeTags")
  -- Buff groups
  self.armorBonusGroup = effect.addStatModifierGroup({})
  self.weaponBonusGroup = effect.addStatModifierGroup({})
  self.biomeBonusGroup = effect.addStatModifierGroup({})

  script.setUpdateDelta(5)

  -- Initial application of armor effects.
  self:applyArmorBonuses()
  self:updateWeaponBonuses()
  self:updateBiomeBonuses()
  self:updateMovementBonuses()
  self:updateEphemeralEffects()
end

function SetBonusHelper.uninit(self)
  self:removeArmorBonuses()
  self:removeWeaponBonuses()
  self:removeBiomeBonuses()
  self:removeEphemeralEffects()
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function SetBonusHelper.itemTagInList(self, item, tags)
  -- Assumes that item exists.
  for _, tag in pairs(tags) do
    if (root.itemHasTag(item, tag)) then
      return true
    end
  end
  return false
end

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

--=========================== ARMOR BONUS FUNCTIONS ==========================--

function SetBonusHelper.applyArmorBonuses(self)
  local newGroup = {}
  for stat, bonus in pairs(self.armorBonuses) do
    local next = self:getBonusGroupFromTable(tostring(stat), bonus)
    if (next ~= false) then
      table.insert(newGroup, next)
    end
  end
  -- Update armor bonus modifier group.
  effect.setStatModifierGroup(self.armorBonusGroup, newGroup)
end

function SetBonusHelper.removeArmorBonuses(self)
  effect.removeStatModifierGroup(self.armorBonusGroup)
  self.armorBonusGroup = effect.addStatModifierGroup({})
end

function SetBonusHelper.updateEphemeralEffects(self)
  if (self.armorEphemeralEffects ~= nil) then
    for _, effect in pairs(self.armorEphemeralEffects) do
      status.addEphemeralEffect(effect)
    end
  end
end

function SetBonusHelper.removeEphemeralEffects(self)
  if (self.armorEphemeralEffects ~= nil) then
    for _, effect in pairs(self.armorEphemeralEffects) do
      status.removeEphemeralEffect(effect)
    end
  end
end

--========================== WEAPON BONUS FUNCTIONS ==========================--

function SetBonusHelper.checkWeapons(self, type, tags, altTags)
  -- Return false if there are no weapon tags, or if the player is unarmed.
  if (tags == nil) then return false end
  if (self.currentPrimary == nil and self.currentAlt == nil) then return false end
  -- 1. Dual-wielding criteria
  if (type == "dual") then
    -- Return false if there are no alt weapon tags, or if not dual-wielding.
    if (altTags == nil) then return false end
    if (self.currentPrimary == nil or self.currentAlt == nil) then return false end
    -- Return true if primary and alt match tags and altTags.
    return ((self:itemTagInList(self.currentPrimary, tags) and self:itemTagInList(self.currentAlt, altTags))
      or (self:itemTagInList(self.currentPrimary, altTags) and self:itemTagInList(self.currentAlt, tags)))
  -- 2. Two-handed criteria
  elseif (type == "twohand") then
    -- Return false if primary is empty or alt is not empty.
    if (self.currentAlt ~= nil or self.currentPrimary == nil) then return false end
    -- Check that primary is two-handed.
    local desc = world.entityHandItemDescriptor(entity.id(), "primary")
    local twohanded = (desc ~= nil and root.itemConfig(desc).config.twoHanded) or false
    -- Return true if primary is two-handed and matches tags.
    return (twohanded and self:itemTagInList(self.currentPrimary, tags))
  elseif (type == "any") then
    -- Return true if primary exists and matches tags.
    if (self.currentPrimary ~= nil) then
      if (self:itemTagInList(self.currentPrimary, tags)) then return true end
    end
    -- Also return true if alt exists and matches tags.
    if (self.currentAlt ~= nil) then
      if (self:itemTagInList(self.currentAlt, tags)) then return true end
    end
    -- Otherwise, return false.
    return false
  end
  -- Undefined criteria type! Return false by default.
  return false
end

function SetBonusHelper.updateWeaponBonuses(self)
  -- Exit if there are no weapon bonuses.
  if (self.weaponBonuses == nil) then return end
  local newPrimary = world.entityHandItem(entity.id(), "primary")
  local newAlt = world.entityHandItem(entity.id(), "alt")
  -- Check if the player's equipped items have changed. Exit if they haven't.
  if ((self.currentPrimary == newPrimary) and (self.currentAlt == newAlt)) then return end
  self.currentPrimary = newPrimary
  self.currentAlt = newAlt
  -- Go through applicable weapon bonuses and apply the first one that matches.
  local newGroup = {}
  for _, bonus in pairs(self.weaponBonuses) do
    local type = bonus.type
    local tags = bonus.tags
    local altTags = bonus.altTags -- may be nil
    if (self:checkWeapons(type, tags, altTags) == true) then
      for name, stat in pairs(bonus.stats) do
        local next = self:getBonusGroupFromTable(tostring(name), stat)
        if (next ~= false) then
          table.insert(newGroup, next)
        end
      end
      break -- Do not check any more bonuses.
    end
  end
  if (newGroup ~= {}) then
    effect.setStatModifierGroup(self.weaponBonusGroup, newGroup)
  else
    self:removeWeaponBonuses()
  end
end

function SetBonusHelper.removeWeaponBonuses(self)
  effect.removeStatModifierGroup(self.weaponBonusGroup)
  self.weaponBonusGroup = effect.addStatModifierGroup({})
end

--========================== BIOME BONUS FUNCTIONS ==========================--

function SetBonusHelper.checkBiome(self)
  local tags = self.biomeTags
  if (tags == nil) then return false end
  for _, tag in pairs(tags) do
    if (self.currentBiome == tag) then return true end
  end
  return false
end

function SetBonusHelper.updateBiomeBonuses(self)
  -- Exit if there are no biome bonuses.
  if (self.biomeBonuses == nil) then return end
  -- Check for a biome change. Exit if it is the same as before.
  local newBiome = world.type()
  if (self.currentBiome == newBiome) then return end
  self.currentBiome = newBiome
  if (self:checkBiome() == true) then
    local newGroup = {}
    for stat, bonus in pairs(self.biomeBonuses) do
      local next = self:getBonusGroupFromTable(tostring(stat), bonus)
      if (next ~= false) then
        table.insert(newGroup, next)
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

--========================= MOVEMENT BONUS FUNCTIONS =========================--

--[[ NOTE: This function adds together any speed/jump bonuses from the regular
    set bonus with any biome-specific bonuses. There are currently no cases
    where a weapon type provides such bonuses (except in FR). ]]--
function SetBonusHelper.updateMovementBonuses(self)
  local speed = 1.0
  local jump = 1.0
  local armorMods = self.armorMovementModifiers
  if (armorMods ~= nil) then
    if (armorMods.speed ~= nil) then
      speed = speed + armorMods.speed - 1.0
    end
    if (armorMods.jump ~= nil) then
      jump = jump + armorMods.jump - 1.0
    end
  end
  local biomeMods = self.biomeMovementModifiers
  if (self:checkBiome() and biomeMods ~= nil) then
    if (biomeMods.speed ~= nil) then
      speed = speed + biomeMods.speed - 1.0
    end
    if (biomeMods.jump ~= nil) then
      jump = jump + biomeMods.jump - 1.0
    end
  end
  mcontroller.controlModifiers({
    speedModifier = speed,
    airJumpModifier = jump
  })
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function SetBonusHelper.update(self)
  -- Update weapon and biome bonuses, which change with player's equipment/location.
  self:updateWeaponBonuses()
  self:updateBiomeBonuses()
  -- Apply movement modifiers (these need to be set every update)
  self:updateMovementBonuses()
  -- Apply any extra ephemeral status effects (which also need to be refreshed).
  self:updateEphemeralEffects()
end
