function init()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  script.setUpdateDelta(0)
end
