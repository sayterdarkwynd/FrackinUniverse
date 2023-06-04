require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuJungleWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuJungleWeather.init(self, config_file)
  self.parent.init(self, config_file)
  -- Health percentage below which movement becomes penalised.
  self.movementPenaltyHealthThreshold = 0.5
end

--[[ Modified function only applies movement penalties when health is below
    a threshold percentage. The penalty scales up as health decreases. ]]--
-- TODO: Maybe a new SAIL warning that plays when this happens?
function fuJungleWeather.applyMovementPenalties(self, modifier)
  local healthPercent = status.resource("health") / status.stat("maxHealth")
  if (healthPercent < self.movementPenaltyHealthThreshold) then
    local healthModifier = 1.0 - (healthPercent / self.movementPenaltyHealthThreshold)
    self.parent.applyMovementPenalties(self, modifier * healthModifier)
  end
end

--============================= GRAPHICAL EFFECTS ============================--

function fuJungleWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=ff7600=0.05")
end

function fuJungleWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=ff7600=0.0")
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuJungleWeather:init(tostring(config_file))
end

function uninit()
  fuJungleWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuJungleWeather:update(dt)
end
