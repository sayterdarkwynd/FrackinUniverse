function init()
  storage.currentState = storage.currentState or false
  output(storage.state)
end

--ternary operator
function toggleState(condition,iftrue,iffalse)
    if condition then return iftrue else return iffalse end
end

-- Change Animation
function output(state)
  if stateCurrent ~= storage.currentState then
    storage.currentState = stateCurrent
    animator.setAnimationState("pumpoutState",toggleState(stateCurrent,"on","off"))
  end
end

--update animation and outputwire
function update(dt)
    local isConnected = object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)
    output(isConnected)
    object.setAllOutputNodes(isConnected)
end