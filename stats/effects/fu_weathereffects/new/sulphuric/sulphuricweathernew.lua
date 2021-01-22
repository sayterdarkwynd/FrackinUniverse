require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuSulphuricWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuSulphuricWeather.init(self, config_file)
  self.parent.init(self, config_file)
  -- Protection threshold before health drain starts.
  self.protectionThreshold = 1
end

function fuSulphuricWeather.applyHealthDrain(self, modifier, dt)
  -- Only drain health once player's protection is depleted.
  if status.stat("protection") < 1 then
    self.parent.applyHealthDrain(self, modifier, dt)
  end
end

--============================= GRAPHICAL EFFECTS ============================--

function fuSulphuricWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=ffbe22=0.3")
end

function fuSulphuricWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=ffbe22=0")
end

function fuSulphuricWeather.createAlert(self)
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
	-- Hurt the player as an extra warning.
	self:applySelfDamage(0.1)
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuSulphuricWeather:init(tostring(config_file))
end

function uninit()
  fuSulphuricWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuSulphuricWeather:update(dt)
end
