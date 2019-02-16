function init()
  storage.currentState = storage.currentState or false
  output(storage.currentState)
end

function output(stateCurrent)
  if stateCurrent ~= storage.currentState then
    storage.currentState = stateCurrent
  end
  if stateCurrent then
      animator.setAnimationState("outputState","on")
  else
      animator.setAnimationState("outputState","off")
  end
end

function update(dt)
    local isConnected = object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)
    output(isConnected)
    object.setAllOutputNodes(isConnected)
end