RandomStateInitializer = {};

function RandomStateInitializer.init(animationStatePrefix, numberOfStates)
  if (storage == nil or animator == nil) then
    return;
  end
  if(storage.animationSelected ~= nil) then
    return;
  end
  if(animationStatePrefix == nil) then
    return;
  end
  if(numberOfStates == nil or numberOfStates < 1) then
    return;
  end
	local randomState = math.random(numberOfStates);
  storage.animationSelected = randomState;
  animator.setAnimationState("switchState", animationStatePrefix .. randomState)
end