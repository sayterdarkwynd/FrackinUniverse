require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuDesertWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuDesertWeather.init(self, config_file)
  self.parent.init(self, config_file)
  --[[ When the player gets wet or goes underground, they are protected from
      desert heat for the duration of the grace period. ]]--
  self.gracePeriod = 0
  self.graceLength = 60
end

function fuDesertWeather.totalModifier(self)
  local totalModifier = self:resistModifier()
  -- Apply bright light modifier during daytime.
  if (self:isDaytime()) and (not self:isUnderground()) and (self:lightLevel() > 75) then
    totalModifier = totalModifier * self.modifiers["bright"]
  end
  if (self.modifiers["night"] ~= nil) and not (self:isDaytime() or self:isUnderground()) then
    totalModifier = totalModifier * self.modifiers["night"] -- zero
    -- Don't send "night" warning here - it's time-of-day based in deserts.
  end
  if (self.modifiers["underground"] ~= nil) and (self:isUnderground()) then
    totalModifier = totalModifier * self.modifiers["underground"] -- zero
    self.gracePeriod = self.graceLength
    self:sendWarning("underground")
  end
  if (self.modifiers["wet"] ~= nil) and (self:isWet()) then
    totalModifier = totalModifier * self.modifiers["wet"] -- zero
    self.gracePeriod = self.graceLength
    self:sendWarning("wet")
  end
  -- No windy modifier for deserts.
  -- Prevent health drain if grace period is active (set modifier to 0).
  if (self.gracePeriod > 0) then
    return 0
  end
  return totalModifier
end

function fuDesertWeather.update(self, dt)
  self.gracePeriod = math.max(self.gracePeriod - dt, 0)
  self.parent.update(self, dt)
  if (self:entityAffected()) and (self.effectActive) then
    -- Send player warnings based on time of day.
    local time = world.timeOfDay()
    if (time < 0.1) then
      if (not self:isUnderground()) then
        self:sendWarning("sunrise")
      end
      -- Re-enable the "night" message.
      self.usedMessages["night"] = nil
    elseif (time > 0.2) and (time < 0.3) then
      if (not self:isUnderground()) then
        self:sendWarning("noon")
      end
    elseif (time > 0.5) then
      if (not self:isUnderground()) then
        self:sendWarning("night")
      end
      -- Re-enable the "sunrise" and "noon" messages.
      self.usedMessages["sunrise"] = nil
      self.usedMessages["noon"] = nil
    end
  end
end


--============================= GRAPHICAL EFFECTS ============================--

function fuDesertWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=ff7600=0.05")
end

function fuDesertWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=ff7600=0.0")
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuDesertWeather:init(tostring(config_file))
end

function uninit()
  fuDesertWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuDesertWeather:update(dt)
end
