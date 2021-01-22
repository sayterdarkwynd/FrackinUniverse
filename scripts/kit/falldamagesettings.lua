settings = {}

settings.stringToInteger = {
  none = 0,
  all = 1,
  aggressive = 2
}

function settings.getSetting(setting, default)
  if not settings.config then
    settings.config = root.assetJson("/kit_falldamagesettings.config")
  end
  return settings.config[setting] ~= nil and settings.config[setting] or default
end