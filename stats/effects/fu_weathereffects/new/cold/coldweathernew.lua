require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuColdWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuColdWeather.init(self, config_file)
  self.parent.init(self, config_file)
  self.iceBreathDelay = 2.4
  self.iceBreathTimer = self.iceBreathDelay
end

function fuColdWeather.update(self, dt)
  self.parent.update(self, dt)
  -- Periodically create player ice breath (even if immune to effect).
  self.iceBreathTimer = math.max(self.iceBreathTimer - dt, 0)
  if (self.iceBreathTimer == 0) then
    self.createIceBreath()
    self.iceBreathTimer = self.iceBreathDelay
  end
end


--============================= GRAPHICAL EFFECTS ============================--

function fuColdWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=3066cc=0.6")
end

function fuColdWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=3066cc=0.0")
end

function fuColdWeather.createIceBreath(self)
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  world.spawnProjectile(
    "iceinvis",
    mouthPosition,
    entity.id(),
    directionTo,
    false,
    {power = 0, damageTeam = sourceDamageTeam}
  )
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuColdWeather:init(tostring(config_file))
end

function uninit()
  fuColdWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuColdWeather:update(dt)
end
