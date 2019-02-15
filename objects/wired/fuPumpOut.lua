function init()
  storage.currentState = storage.currentState or false
  output(storage.currentState)
end

function toggleState(condition,iftrue,iffalse)
    if condition then 
      return iftrue 
    else 
      return iffalse 
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