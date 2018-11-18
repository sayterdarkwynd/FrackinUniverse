require "/scripts/vec2.lua"
require "/scripts/util.lua"

fuWeather = {}

--============================= CLASS CONSTRUCTOR ============================--

function fuWeather:new(obj)
  obj = obj or {} -- initialise object table if not given
  setmetatable(obj, self)
  self.__index = self -- allow object to inherit parent methods
  obj.parent = self -- manually allow access to overwritten parent methods
  return obj
end

--============================== INIT AND UNINIT =============================--

function fuWeather:init(config_file)
  -- Environment Configuration --
  local effectConfig = root.assetJson(config_file).effectConfig
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
  self.speedMin = effectConfig.speedMin
  self.jumpMin = effectConfig.jumpMin
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
  self.checkEffect()

  -- Define script update interval --
  script.setUpdateDelta(5)
end

function fuWeather:uninit()
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function fuWeather:totalResist()
  local totalResist = 0
  for resist, multiplier in pairs(self.resistanceTypes) do
    totalResist = totalResist + (status.stat(resist,0) * multiplier)
  end
  return totalResist
end

function fuWeather:resistModifier()
  local totalResist = self.totalResist()
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

function fuWeather:entityAffected()
  -- if player has the correct immunity stat, return false
  for _,stat in pairs(self.immunityStats) do
    if status.statPositive(stat) then
      return false
    end
  end
  -- if player has sufficient total resistances, return false
  if (self.totalResist() >= self.resistanceThreshold) do
    return false
  end
  return true
end

function fuWeather:applyEffect()
  self.activateVisualEffects()
  self.effectActive = true
end

function fuWeather:removeEffect()
  self.deactivateVisualEffects()
  self.effectActive = false
  --effect.expire() -- This destroys the instance, right?
end

--[[ Checks whether or not the effect should be active, changes the effect's
    stat if necessary, and tries to play the "intro" warning message if it
    hasn't been played yet. ]]--
function fuWeather:checkEffect()
  --[[ if not a player, or world type is "unknown" (on ship) then remove the
      effect and expire (should destroy this instance). ]]--
  if ((world.entityType(entity.id()) ~= "player")
  or world.type()=="unknown") then
    self.removeEffect()
    effect.expire()
    return
  end
  if self.entityAffected() then
    if (not self.effectActive) then
      self.applyEffect()
    end
    self.sendWarning("intro")
  elseif self.effectActive then
    self.removeEffect()
  end
end

--[[ Send a weather-related warning message to the player. This will only
    succeed if:
    1. The message self.messages[type] is defined
    2. The message timer is zero (cooldown has passed)
    3. The message has not already been sent for this effect instance
    If successful, the message timer will be reset and the message will be
    flagged as used. ]]--
function fuWeather:sendWarning(type)
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

function fuWeather:lightLevel()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

function fuWeather:hungerLevel()
  if status.isResource("food") then
    return status.resource("food")
  else
    return 50
  end
end

function fuWeather:isDaytime()
  return (world.timeOfDay() < 0.5)
end

function fuWeather:isUnderground()
  return world.underground(mcontroller.position())
end

function fuWeather:isWet()
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  return world.liquidAt(mouthPosition)
end

function fuWeather:isWindy()
  return (world.windLevel(mcontroller.position()) > 40)
end

--============================= GRAPHICAL EFFECTS ============================--
--[[ NOTE: These functions are simply much easier to define individually for
    each weather type. I have left these here as an "abstract class"-style
    definition. ]]--

function fuWeather:activateVisualEffects()
end

function fuWeather:deactivateVisualEffects()
end

function fuWeather:createAlert()
end

--============================ DEBUFFING FUNCTIONS ===========================--

function fuWeather:applyDebuffs(modifier)
  modifierGroup = {}
  i = 1
  for dStat, dAmount in pairs(self.debuffs) do
    modifierGroup[i] = {stat = dStat, amount = -dAmount}
    i = i + 1
  end
  effect.addStatModifierGroup(modifierGroup)
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ NOTE: The actual update() function must be defined in each weather
    effect's .lua file. However, the idea is that the majority of what each
    weather effect does can be achieved simply by calling the method
    self.parent.update(). ]]--

function fuWeather:update(dt)
  -- Check that weather effect is (still) active.
  self.checkEffect()
  if (not self.effectActive) then
    return
  end
  -- Tick down timers.
  self.messageTimer = math.max(self.messageTimer - dt, 0)
  self.debuffTimer = math.max(self.debuffTimer - dt, 0)

  -- Calculate the total effect modifier.
  local totalModifier = self.resistModifier()
  if (self.modifiers["night"] ~= nil) and (not self.isDaytime()) then
    totalModifier = totalModifier * self.modifiers["night"]
    self.sendWarning("night")
  end
  if (self.modifiers["underground"] ~= nil) and (self.isUnderground()) then
    totalModifier = totalModifier * self.modifiers["underground"]
    self.sendWarning("underground")
  end
  if (self.modifiers["wet"] ~= nil) and (self.isWet()) then
    totalModifier = totalModifier * self.modifiers["wet"]
    self.sendWarning("wet")
  end
  if (self.modifiers["windy"] ~= nil) and (self.isWindy()) then
    totalModifier = totalModifier * self.modifiers["windy"]
    self.sendWarning("windy")
  end

  -- Apply health drain.
  if (self.baseHealthDrain > 0) then
    local healthDrain = self.baseHealthDrain * totalModifier
    status.modifyResource("health", -healthDrain * dt)
  end
  -- Apply hunger drain (if not casual).
  if status.isResource("food") then
    if (status.resource("food") >= 2) then
      local hungerDrain = self.baseHungerDrain * totalModifier
      status.modifyResource("food", -hungerDrain * dt)
    end
  end
  -- Apply speed and jump penalties.
  local speedMod = 1.0
  local jumpMod = 1.0
  if (self.baseSpeedPenalty > 0) then
    speedMod = speedMod - (self.baseSpeedPenalty * totalModifier)
  end
  if (self.baseJumpPenalty > 0) then
    jumpMod = jumpMod - (self.baseJumpPenalty * totalModifier)
  end
  -- Clamp modifiers between specified minimum and 1.0.
  mcontroller.controlModifiers({
    speedModifier = math.min(math.max(speedMod, self.speedMin), 1.0)
    airJumpModifier = math.min(math.max(jumpMod, self.jumpMin), 1.0)
  })
  -- Periodically apply any stat debuffs.
  if (self.debuffTimer == 0) then
    self.applyDebuffs(totalModifier)
    self.debuffTimer = self.baseDebuffRate
  end
end
