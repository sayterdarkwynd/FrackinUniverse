require "/scripts/vec2.lua"


function init()
  object.setInteractive(true)
end

function onInteraction(args)
  object.smash()
end


function die(smash)
  if smash then
    world.spawnProjectile(config.getParameter("explosionProjectile", "explosivebarrel"), vec2.add(object.position(), config.getParameter("explosionOffset", {0,0})), entity.id(), {0,0})
  end
end