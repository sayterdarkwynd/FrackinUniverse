require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--fuHeatWeather = fuWeather.new{}

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

function makeAlert()
  animator.playSound("bolt")
end

--=========================== MAIN UPDATE FUNCTION ==========================--

function update(dt)
  fuWeatherBase.update(self, dt)
end
