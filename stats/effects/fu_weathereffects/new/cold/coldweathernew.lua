require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================== INIT AND UNINIT =============================--

function init()
  local config_file = config.getParameter("configPath")
  fuWeatherBase.init(self, tostring(config_file))
  self.iceBreathDelay = 2.4
  self.iceBreathTimer = self.iceBreathDelay
end

function uninit()
  fuWeatherBase.uninit(self)
end

--============================= GRAPHICAL EFFECTS ============================--

function activateVisualEffects()
  effect.setParentDirectives("fade=3066cc=0.6")
end

function deactivateVisualEffects()
  effect.setParentDirectives("fade=3066cc=0.0")
end

function createAlert()
end

--===================== OTHER WEATHER-SPECIFIC FUNCTIONS ====================--

function createIceBreath()
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

function extraModifier()
  return 1.0
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function update(dt)
  fuWeatherBase.update(self, dt)
  -- Separate timer for player ice breath (even if immune).
  self.iceBreathTimer = math.max(self.iceBreathTimer - dt, 0)
  if (self.iceBreathTimer == 0) then
    createIceBreath()
    self.iceBreathTimer = self.iceBreathDelay
  end
end
