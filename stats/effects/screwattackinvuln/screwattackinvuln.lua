function init()

  animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparks", true)
  animator.playSound("screwattack_start")
  effect.setParentDirectives("?fade=29F77B=0.4")
  --animator.playSound("timefreeze_loop", -1)
  
  -- effect.addStatModifierGroup({
  --   {stat = "invulnerable", amount = 1}
  -- })
  self.soundTimer = 0.5
  self.soundFlag = false

  self.flip = false
  self.colorTimer = 0.1

  self.screwProj = world.spawnProjectile("screwattackproj", mcontroller.position(), entity.id(), {0,0}, true)
end

function update(dt)

  -- if self.flip > 2 then
  --   self.flip = 0
  -- end

  world.callScriptedEntity(self.screwProj, "projectile.setTimeToLive", 3.0)


  if self.colorTimer < 0 then
    if not self.flip then
      effect.setParentDirectives("?fade=29A529=0.4")
    else
      effect.setParentDirectives("?fade=29F77B=0.4")
    end
    self.colorTimer = 0.1
    self.flip = not self.flip
  end

  self.colorTimer = self.colorTimer - dt
  --effect.setParentDirectives("?fade=29F77B=".. (0.4*self.flip))

  --self.flip = self.flip + 1

  if mcontroller.onGround() then
    world.callScriptedEntity(self.screwProj, "projectile.die")
    effect.expire()
    animator.stopAllSounds("screwattack_loop")
  else
    effect.addStatModifierGroup({
      {stat = "invulnerable", amount = 1}
    })
    effect.modifyDuration(10)
  end

  self.soundTimer = self.soundTimer - dt

  if self.soundTimer < 0 and not self.soundFlag then
    animator.playSound("screwattack_loop", -1)
    self.soundFlag = true
  end

end

function uninit()
  
end
