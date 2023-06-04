require "/scripts/effectUtil.lua"

function init()
  self.range = config.getParameter("range", 80)
  power()
end

function update(dt)
  if storage.state then
    effectUtil.effectAllInRange("fu_byosgravgenfield", self.range, 10)
  end
end

function onInputNodeChange()
  power()
end

function onNodeConnectionChange()
  power()
end

function power()
  storage.state=not object.isInputNodeConnected(0) or object.isInputNodeConnected(0) and object.getInputNodeLevel(0)
end
