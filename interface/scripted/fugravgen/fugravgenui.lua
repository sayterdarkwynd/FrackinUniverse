function init()
  --[[local hideExpansionSlots = config.getParameter("hideExpansionSlots")
  widget.setChecked("btnHideExpansionSlots", hideExpansionSlots)]]--

  local gravity = config.getParameter("gravity")
  widget.setSliderValue("sldGravity", gravity)
end

function update()

end

--[[function setHideExpansionSlots(widgetName, widgetData)
  local hidden = widget.getChecked(widgetName)
  world.sendEntityMessage(pane.sourceEntity(), "setHideExpansionSlots", hidden)
end]]--

function setGravity(widgetName, widgetData)
  local gravity = widget.getSliderValue(widgetName)
  world.sendEntityMessage(pane.sourceEntity(), "setGravity", gravity)
end
