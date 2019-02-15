function init()
  storage.currentState = storage.currentState or false
  output(storage.currentState)
end

function toggleState(condition,positive,negative)
    if condition then 
      return positive 
    else 
      return negative 
    end
end

function output(state)
  if stateCurrent ~= storage.currentState then
    storage.currentState = stateCurrent
    animator.setAnimationState("outputState",toggleState(stateCurrent,"on","off"))
  end
end

function update(dt)
    local isConnected = object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)
    output(isConnected)
    object.setAllOutputNodes(isConnected)
end