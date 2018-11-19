require "/scripts/vec2.lua"
require "/scripts/util.lua"

fuWeatherBase = {}

--============================= CLASS DEFINITION ============================--

function fuWeatherBase.new(self, child)
  child = child or {}
  setmetatable(child, self)
  child.parent = self
  self.__index = self
  return child
end

--============================== INIT AND UNINIT =============================--

function fuWeatherBase.init(self, config_file)
  -- Environment Configuration --
  local effectConfig = root.assetJson(config_file)["effectConfig"]
  --resistances
  self.resistanceTypes = effectConfig.resistanceTypes
  self.resistanceThreshold = effectConfig.resistanceThreshold
  --immunities
  self.immunityStats = effectConfig.immunityStats
  --damage over time
  self.baseHealthDrain = effectConfig.healthDrain
  self.baseHungerDrain = effectConfig.hungerDrain
  --movement penalties
  self.baseSpeedPenalty = effectConfig.speedPenalty
  self.baseJumpPenalty = effectConfig.jumpPenalty
  --debuffs
  self.baseDebuffRate = effectConfig.debuffRate
  self.debuffs = effectConfig.debuffs
  --situational modifiers
  self.modifiers = effectConfig.modifiers
  --messages
  self.messages = effectConfig.messages
  self.usedMessages = {}
  --timers
  self.messageTimer = 0  -- timer until next radio message may play
  self.messageDelay = 20  -- default cooldown for radio messages
  self.debuffTimer = self.baseDebuffRate

  -- Check and apply initial effect --
  self.effectActive = false
  --fuWeatherBase.checkEffect()

  -- Define script update interval --
  script.setUpdateDelta(5)
end

function fuWeatherBase.uninit(self)
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function fuWeatherBase.totalResist(self)
  local totalResist = 0
  for resist, multiplier in pairs(self.resistanceTypes) do
    totalResist = totalResist + (status.stat(resist,0) * multiplier)
  end
  return totalResist
end

function fuWeatherBase.resistModifier(self)
  local totalResist = fuWeatherBase.totalResist(self)
  if (totalResist > 0) then
    if (self.resistanceThreshold > 0) then
      -- Normal case: scale resistance modifier to resistanceThreshold
      return 1.0 - math.min(totalResist / self.resistanceThreshold, 1.0)
    else
      -- Fallback case: if resistanceThreshold is zero for some reason
      return 1.0 - math.min(totalResist, 1.0)
    end
  else
    -- Negative resist case: don't scale to resistanceThreshold
    return 1.0 - totalResist
  end
end

function fuWeatherBase.entityAffected(self)
  -- if player has the correct immunity stat, return false
  for _,stat in pairs(self.immunityStats) do
    if status.statPositive(stat) then
      return false
    end
  end
  -- if player has sufficient total resistances, return false
  if (fuWeatherBase.totalResist(self) >= self.resistanceThreshold) then
    return false
  end
  return true
end

function fuWeatherBase.applyEffect(self)
  self.activateVisualEffects()
  self.effectActive = true
end

function fuWeatherBase.removeEffect(self)
  self.deactivateVisualEffects() -- locally defined function
  -- Reset used warning messages (in case player only has temporary immunity)
  self.usedMessages = {}
  self.effectActive = false
end

--[[ Checks whether or not the effect should be active, changes the effect's
    stat if necessary, and tries to play the "intro" warning message if it
    hasn't been played yet. ]]--
function fuWeatherBase.checkEffect(self)
  --[[ if not a player, or world type is "unknown" (on ship) then remove the
      effect and expire (should destroy this instance). ]]--
  if ((world.entityType(entity.id()) ~= "player")
  or world.type()=="unknown") then
    self:removeEffect()
    effect.expire()
    return
  end
  if fuWeatherBase.entityAffected(self) then
    if (not self.effectActive) then
      self:applyEffect()
    end
    self:sendWarning("intro")
  elseif self.effectActive then
    self:removeEffect()
  end
end

--[[ Send a weather-related warning message to the player. This will only
    succeed if:
    1. The message self.messages[type] is defined
    2. The message timer is zero (cooldown has passed)
    3. The message has not already been sent for this effect instance
    If successful, the message timer will be reset and the message will be
    flagged as used. ]]--
function fuWeatherBase.sendWarning(self, type)
  if (self.messages[type] ~= nil) then
    if (self.messageTimer <= 0) then
      if (self.usedMessages[type] ~= true) then
        world.sendEntityMessage(entity.id(), "queueRadioMessage", self.messages[type], 1.0)
        self.messageTimer = self.messageDelay
        self.usedMessages[type] = true
      end
    end
  end
end

--============================ CONDITIONAL CHECKS ===========================--

function fuWeatherBase.lightLevel(self)
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

function fuWeatherBase.hungerLevel(self)
  if status.isResource("food") then
    return status.resource("food")
  else
    return 50
  end
end

function fuWeatherBase.isDaytime(self)
  return (world.timeOfDay() < 0.5)
end

function fuWeatherBase.isUnderground(self)
  return world.underground(mcontroller.position())
end

function fuWeatherBase.isWet(self)
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  return world.liquidAt(mouthPosition)
end

function fuWeatherBase.isWindy(self)
  return (world.windLevel(mcontroller.position()) > 40)
end

--============================ DEBUFFING FUNCTIONS ===========================--

--[[ Note that this function also triggers the appropriate warning messages
    for situational effects (wet, underground etc.). ]]--
function fuWeatherBase.totalModifier(self)
  local totalModifier = self:resistModifier()
  if (self.modifiers["night"] ~= nil) and not (self:isDaytime() or self:isUnderground()) then
    totalModifier = totalModifier * self.modifiers["night"]
    self:sendWarning("night")
  end
  if (self.modifiers["underground"] ~= nil) and (self:isUnderground()) then
    totalModifier = totalModifier * self.modifiers["underground"]
    self:sendWarning("underground")
  end
  if (self.modifiers["wet"] ~= nil) and (self:isWet()) then
    totalModifier = totalModifier * self.modifiers["wet"]
    self:sendWarning("wet")
  end
  if (self.modifiers["windy"] ~= nil) and (self:isWindy()) and (not self:isUnderground()) then
    totalModifier = totalModifier * self.modifiers["windy"]
    self:sendWarning("windy")
  end
  return totalModifier
end

function fuWeatherBase.applyHealthDrain(self, modifier, dt)
  if (self.baseHealthDrain > 0) then
    local healthDrain = self.baseHealthDrain * modifier
    status.modifyResource("health", -healthDrain * dt)
  end
end

function fuWeatherBase.applyHungerDrain(self, modifier, dt)
  if status.isResource("food") then
    if (status.resource("food") >= 2) then
      local hungerDrain = self.baseHungerDrain * modifier
      status.modifyResource("food", -hungerDrain * dt)
    end
  end
end

function fuWeatherBase.applyMovementPenalties(self, modifier)
  --[[ NOTE: Base penalties should be less than 1. The totalModifier is capped
      at 1.0 so that the player cannot be stopped completely. ]]--
  local speedPenalty = 0
  local jumpPenalty = 0
  if (self.baseSpeedPenalty > 0) then
    speedPenalty = self.baseSpeedPenalty * math.min(modifier, 1.0)
  end
  if (self.baseJumpPenalty > 0) then
    jumpPenalty = self.baseJumpPenalty * math.min(modifier, 1.0)
  end
  mcontroller.controlModifiers({
    speedModifier = 1.0 - speedPenalty,
    airJumpModifier = 1.0 - jumpPenalty
  })
end

function fuWeatherBase.applyDebuffs(self, modifier)
  modifierGroup = {}
  i = 1
  for dStat, dAmount in pairs(self.debuffs) do
    modifierGroup[i] = {stat = dStat, amount = -dAmount * modifier}
    i = i + 1
  end
  effect.addStatModifierGroup(modifierGroup)
end

--============================= GRAPHICAL EFFECTS ============================--
--[[ NOTE: These functions are simply much easier to define individually for
    each weather type. I have left these here as an "abstract class"-style
    definition. ]]--

function fuWeatherBase.activateVisualEffects(self)
end

function fuWeatherBase.deactivateVisualEffects(self)
end

function fuWeatherBase.createAlert(self)
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ NOTE: The actual update() function must be defined in each weather
    effect's .lua file. However, the idea is that the majority of what each
    weather effect does can be achieved simply by calling the method
    self.parent.update(). ]]--

function fuWeatherBase.update(self, dt)
  -- Check that weather effect is (still) active.
  self:checkEffect()
  if (not self.effectActive) then
    return
  end
  -- Tick down timers.
  self.messageTimer = math.max(self.messageTimer - dt, 0)
  self.debuffTimer = math.max(self.debuffTimer - dt, 0)

  -- Calculate the total effect modifier.
  local modifier = self:totalModifier()

  -- Apply health drain.
  self:applyHealthDrain(modifier, dt)
  -- Apply hunger drain (if not casual).
  self:applyHungerDrain(modifier, dt)
  -- Apply speed and jump penalties.
  self:applyMovementPenalties(modifier)
  -- Periodically apply any stat debuffs. Display alerts (e.g. "-Max HP" popup).
  if (self.debuffTimer == 0) then
    self:applyDebuffs(modifier)
    self:createAlert() -- locally defined function
    self.debuffTimer = self.baseDebuffRate
  end
end
