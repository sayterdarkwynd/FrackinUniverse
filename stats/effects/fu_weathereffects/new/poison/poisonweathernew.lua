require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuPoisonWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuPoisonWeather.init(self, config_file)
  effectConfig = self.parent.init(self, config_file)
  self.debuffStartDelay = effectConfig.debuffStartDelay
  self.debuffStartTimer = 0
  -- Health percentage below which movement becomes penalised.
  self.movementPenaltyHealthThreshold = 0.6
end

function fuPoisonWeather.applyEffect(self)
  self.parent.applyEffect(self)
  local debuffStartMult = nil
  local totalResist = self:totalResist()
  if (totalResist >= 0) then
    debuffStartMult = 1.0 / (1.0 + totalResist / self.resistanceThreshold)
  else
    debuffStartMult = 1.0 / math.max(1.0 + totalResist, 0.5)
  end
  self.debuffStartTimer = self.debuffStartDelay * debuffStartMult
end

--[[ Modified function only applies movement penalties when health is below
    a threshold percentage. The penalty scales up as health decreases. ]]--
function fuPoisonWeather.applyMovementPenalties(self, modifier)
  local healthPercent = status.resource("health") / status.stat("maxHealth")
  if (healthPercent < self.movementPenaltyHealthThreshold) then
    local healthModifier = 1.0 - (healthPercent / self.movementPenaltyHealthThreshold)
    self.parent.applyMovementPenalties(self, modifier * healthModifier)
  end
end

--[[ Modified function does not apply debuffs until the debuffStartTimer has
    expired, and only while power >= 0.05. ]]--
function fuPoisonWeather.applyDebuffs(self, modifier)
  if (self.debuffStartTimer == 0) then
    if (status.stat("powerMultiplier") >= 0.05) then
      self.parent.applyDebuffs(self, modifier)
    end
  end
end

function fuPoisonWeather.update(self, dt)
  self.parent.update(self, dt)
  if (self.effectActive) then
    self.debuffStartTimer = math.max(self.debuffStartTimer - dt, 0)
  end
end


--============================= GRAPHICAL EFFECTS ============================--

function fuPoisonWeather.activateVisualEffects(self)
  effect.setParentDirectives("fade=558833=0.7")
  animator.setParticleEmitterOffsetRegion("poisonbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("poisonbreath", true)
end

function fuPoisonWeather.deactivateVisualEffects(self)
  effect.setParentDirectives("fade=558833=0.0")
  animator.setParticleEmitterActive("poisonbreath", false)
end

function fuPoisonWeather.createAlert(self)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  animator.playSound("bolt")
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuPoisonWeather:init(tostring(config_file))
end

function uninit()
  fuPoisonWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuPoisonWeather:update(dt)
end
