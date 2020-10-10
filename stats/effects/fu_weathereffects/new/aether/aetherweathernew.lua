require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuAetherWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuAetherWeather.init(self, config_file)
  self.parent.init(self, config_file)
  self.energyDrainThreshold = 20
end

function fuAetherWeather.applyHealthDrain(self, modifier, dt)

  -- Only apply health drain if max energy is below threshold.
  if (status.stat("maxEnergy") < self.energyDrainThreshold) then
    self.parent.applyHealthDrain(self, modifier, dt)
  end
end

function fuAetherWeather.applyEnergyDrain(self, modifier, dt)
  -- Only apply energy drain if max energy is below threshold.
  if (status.stat("maxEnergy") < self.energyDrainThreshold) then
    self.parent.applyEnergyDrain(self, modifier, dt)
  end
end

--============================= GRAPHICAL EFFECTS ============================--

function fuAetherWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=ff23cc=0.3")
end

function fuAetherWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=ff23cc=0.0")
end

function fuAetherWeather.createAlert(self)
	if entity.entityType()=="player" then
		local statusTextRegion = {0, 1, 0, 1}
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuAetherWeather:init(tostring(config_file))
end

function uninit()
  fuAetherWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuAetherWeather:update(dt)
end
