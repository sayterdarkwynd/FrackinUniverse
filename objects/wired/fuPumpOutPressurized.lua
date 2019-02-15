function init()
  storage.currentState = storage.currentState or false
  output(storage.stateCurrent)
end

--ternary operator
function toggleState(condition,iftrue,iffalse)
    if condition then return iftrue else return iffalse end
end

-- Change Animation
function output(state)
  if stateCurrent ~= storage.currentState then
    storage.currentState = stateCurrent
    animator.setAnimationState("pumpoutpressureState",toggleState(stateCurrent,"on","off"))
  end
end

--update animation and outputwire
function update(dt)
    local con = object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)
    output(con)
    object.setAllOutputNodes(con)
end