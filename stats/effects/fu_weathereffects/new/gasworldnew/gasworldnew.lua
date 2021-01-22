require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuPressureWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuPressureWeather.init(self, config_file)
  effectConfig = self.parent.init(self, config_file)
  self.pressureDamage = effectConfig.pressureDamage
  self.pressureTicks = 0
end

--[[ Instead of applying regular debuffs, high pressure just applies a large
    amount of damage periodically, along with a graphical alert. ]]--
function fuPressureWeather.applyDebuffs(self, modifier)
  local damage = self.pressureDamage.base + (self.pressureTicks * self.pressureDamage.increase)
  self:applySelfDamage(damage * modifier) -- type = nil should be generic physical
  self:createAlert()
  self.pressureTicks = self.pressureTicks + 1
end

function fuPressureWeather.removeDebuffs(self)
  self.pressureTicks = 0
end

function fuPressureWeather.update(self, dt)
  self.parent.update(self, dt)
  -- Extra hook to play the daytime warning message.
  if self.effectActive then
    if (self:isDaytime()) then
      self:sendWarning("day")
    end
  end
end

--============================= GRAPHICAL EFFECTS ============================--

function fuPressureWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=306630=0.8")
end

function fuPressureWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=306630=0.0")
end

function fuPressureWeather.createAlert(self)
  world.spawnProjectile(
    "teslaboltsmall",
    mcontroller.position(),
    entity.id(),
    directionTo,
    false,
    {power = 0, damageTeam = sourceDamageTeam}
  )
  animator.playSound("bolt")
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
  fuPressureWeather:init(tostring(config_file))
end

function uninit()
  fuPressureWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuPressureWeather:update(dt)
end
