function init()
  storage.state = storage.state or false
  output(storage.state)
end

--ternary operator
function fif(condition,iftrue,iffalse)
    if condition then return iftrue else return iffalse end
end

-- Change Animation
function output(state)
  if state ~= storage.state then
    storage.state = state
    animator.setAnimationState("pumpoutpressureState",fif(state,"on","off"))
  end
end

--update animation and outputwire
function update(dt)
    local con = object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)
    output(con)
    object.setAllOutputNodes(con)
end