require "/scripts/randomstateinitializer.lua"

function init(args)
  if(config == nil) then
    return;
  end
  local animationStatePrefix = config.getParameter("animationStatePrefix", "state");
  local numberOfImages = config.getParameter("numberOfImages", 0);
  RandomStateInitializer.init(animationStatePrefix, numberOfImages);
end