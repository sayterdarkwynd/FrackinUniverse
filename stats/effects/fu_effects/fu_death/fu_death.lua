function init()
  deathTimer = config.getParameter("deathTimer")
end

function update(dt)
  deathTimer = deathTimer - dt
  if deathTimer <= 0 then
    effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = -88}})
  end
end