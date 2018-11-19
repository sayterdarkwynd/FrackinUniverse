require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--============================== INIT AND UNINIT =============================--

function init()
  local config_file = config.getParameter("configPath")
  fuWeatherBase.init(self, tostring(config_file))
end

function uninit()
  fuWeatherBase.uninit(self)
end

--============================= GRAPHICAL EFFECTS ============================--

function activateVisualEffects()
  effect.setParentDirectives("fade=ff7600=0.7")
end

function deactivateVisualEffects()
  effect.setParentDirectives("fade=ff7600=0.0")
end

function createAlert() -- NOTE: Not used for heat.
  animator.playSound("bolt")
end

--===================== OTHER WEATHER-SPECIFIC FUNCTIONS ====================--

function extraModifier()
  return 1.0
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function update(dt)
  fuWeatherBase.update(self, dt)
end
