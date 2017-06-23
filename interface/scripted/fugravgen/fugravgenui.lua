function init()
  local gravity = config.getParameter("gravity")
  widget.setSliderValue("sldGravity", gravity)
end

function update()

end

function setGravity(widgetName, widgetData)
  local gravity = widget.getSliderValue(widgetName)
  world.sendEntityMessage(pane.sourceEntity(), "setGravity", gravity)
end
