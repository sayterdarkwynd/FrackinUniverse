function clearAnimation()
  self.animationControls = self.animationControls or {}
  self.animateFallbacks = self.animateFallbacks or {}
  self.animationControls = util.map(self.animationControls, function() return false end)

  self.emitterControls = self.emitterControls or {}
  self.emitterControls = util.map(self.emitterControls, function() return false end)

  self.transformationControls = self.transformationControls or {}
  self.transformationControls = util.map(self.transformationControls, function() return false end)

  self.soundLoops = self.soundLoops or {}
  self.soundLoops = util.map(self.soundLoops, function() return false end)
end

function controlAnimation(stateType, state, fallback)
  if fallback == "" then
    fallback = nil
  end
  self.animateFallbacks[stateType] = fallback
  self.animationControls[stateType] = true
end

function controlEmitter(emitter)
  self.emitterControls[emitter] = true
end

function controlTransformation(group)
  self.transformationControls[group] = true
end

function controlLoopSound(sound)
  self.soundLoops[sound] = true
end

function updateAnimation()
  local fallbacks = {}
  for _,stateType in pairs(util.keys(self.animationControls)) do
    local fallback = self.animateFallbacks[stateType]
    if not self.animationControls[stateType] then
      if fallback then
        animator.setAnimationState(stateType, fallback)
      end
      self.animationControls[stateType] = nil
    else
      fallbacks[stateType] = fallback
    end
  end
  self.animateFallbacks = fallbacks

  local emitters = {}
  for emitter,v in pairs(self.emitterControls) do
    if v == false then
      animator.setParticleEmitterActive(emitter, false)
    else
      emitters[emitter] = v
    end
  end
  self.emitterControls = emitters

  local transformations = {}
  for group,v in pairs(self.transformationControls) do
    if v == false then
      animator.resetTransformationGroup(group)
    else
      transformations[group] = v
    end
  end
  self.transformationControls = transformations

  local sounds = {}
  for soundName,v in pairs(self.soundLoops) do
    if v == false then
      animator.stopAllSounds(soundName)
    else
      sounds[soundName] = v
    end
  end
  self.soundLoops = sounds
end

-- param type
-- param state
function setAnimationState(args, board)
  if args.type == nil or args.state == nil or args.type == "" or args.state == "" then
    return false
  end

  self.animateFallbacks[args.type] = nil
  animator.setAnimationState(args.type, args.state)
  return true
end

-- Requires the entity to call clearAnimation before running the behavior
-- and updateAnimation after
-- Holds an animation until it is no longer called
-- param type
-- param state
function animate(args, board)
  if args.state == nil or args.state == "" then
    return false
  end

  animator.setAnimationState(args.type, args.state)
  while true do
    controlAnimation(args.type, args.state, args.fallback)
    coroutine.yield()
  end
end

-- param sound
function loopSound(args, board)
  animator.playSound(args.sound, -1)
  while true do
    controlLoopSound(args.sound)
    coroutine.yield()
  end
end

-- param type
-- param tag
function setGlobalTag(args, board)
  if args.type == nil or args.type == ""then
    return false
  end

  animator.setGlobalTag(args.type, args.tag or "")
  return true
end

-- param group
-- param rotation
-- param rotationCenter
-- param translation
function transform(args, board)
  while true do
    controlTransformation(args.group)

    animator.resetTransformationGroup(args.group)
    if args.rotation then
      if args.rotationCenter then
        animator.rotateTransformationGroup(args.group, args.rotation, args.rotationCenter)
      else
        animator.rotateTransformationGroup(args.group, args.rotation)
      end
    end
    if args.translation then
      animator.translateTransformationGroup(args.group, args.translation)
    end

    coroutine.yield()
  end
end

-- param transformationGroup
function resetTransformationGroup(args, board)
  if args.transformationGroup == nil then return false end
  animator.resetTransformationGroup(args.transformationGroup)
  return true
end

-- param transformationGroup
-- param angle
-- param rotationCenter
function rotateTransformationGroup(args, board)
  if args.angle == nil or args.transformationGroup == nil or args.transformationGroup == "" then
    return false
  end

  animator.rotateTransformationGroup(args.transformationGroup, args.angle, args.rotationCenter)
  return true
end

-- param transformationGroup
-- param offset
function translateTransformationGroup(args, board)
  animator.translateTransformationGroup(args.transformationGroup, args.offset)
  return true
end

function scaleTransformationGroup(args, board)
  animator.scaleTransformationGroup(args.transformationGroup, args.scale)
  return true
end

-- param emitter
function burstParticleEmitter(args, board)
  if args.emitter == nil or args.emitter == "" then return false end

  animator.burstParticleEmitter(args.emitter)
  return true
end

-- param emitter
-- param active
function setParticleEmitterActive(args, board)
  if args.emitter == nil then return false end

  animator.setParticleEmitterActive(args.emitter, args.active)
  return true
end

-- param emitter
function emitParticles(args, board)
  animator.setParticleEmitterActive(args.emitter, true)
  while true do
    controlEmitter(args.emitter)
    coroutine.yield()
  end
end

-- param sound
-- param loops
function playSound(args, board)
  if args.sound == "" then return false end
  animator.playSound(args.sound, args.loops)
  return true
end

-- param sound
function stopAllSounds(args, board)
  animator.stopAllSounds(args.sound)
  return true
end

-- param light
-- param active
function setLightActive(args, board)
  if args.light == nil or args.active == nil then return false end

  animator.setLightActive(args.light, args.active)
  return true
end

-- param partName
-- param propertyName
function partPoint(args, board)
  local partpoint = animator.partPoint(args.partName, args.propertyName)
  return true, {partpoint = partpoint}
end