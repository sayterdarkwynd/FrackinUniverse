require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/monsters/monster.lua"

local monsterinit = init
local monsterupdate = update

function init()

  monsterinit()

  self.radius = 5
  self.spokeCount = 12


  self.step = 0.25
  self.waveHeight = 2.5

end

function update(dt)

  self.monsterupdate = self.monsterupdate and self.monsterupdate or monsterupdate
  self.monsterupdate(dt)

  local target = util.closestValidTarget(120)
  
  if target then
      local targetPosition = world.entityPosition(target)
      local angle = vec2.angle(vec2.sub(targetPosition,mcontroller.position()))
      local step = vec2.withAngle(angle,self.radius)
      local distance = vec2.mag(vec2.sub(mcontroller.position(),targetPosition))
      local path = {mcontroller.position()}
      local orientation = 1
      local facingDirection = mcontroller.position()[1] < targetPosition[1] and 1 or -1
      local junction = mcontroller.position()
      local close = false
      local axis 
      for axii=1,math.max(1,distance/self.radius),2 do

        local angle = vec2.angle(vec2.sub(targetPosition,junction))

        local distance = vec2.mag(vec2.sub(junction,targetPosition))

        local closeStep = distance < self.radius * 3 and vec2.withAngle(angle,distance/2) or nil

        axis = vec2.add(junction,vec2.mul(closeStep and closeStep or step,axii))
      
        util.debugPoint(axis,{255,0,255})
        
        orientation = orientation * -1

        for spoke = self.spokeCount / 2 + 1, self.spokeCount do 

          local spokeAngle = angle - orientation * facingDirection * spoke * math.pi*2 / self.spokeCount
          local spokeVector = vec2.withAngle(spokeAngle, closeStep and distance/2 or self.radius)
          local spokeEnd = vec2.add(spokeVector,axis)
          path[#path+1] = spokeEnd

        end

        junction = axii % 2 == 0 and axis or junction

      end
        
      if #path > 1 then
    
        for i = 2, #path do
    
          util.debugLine(path[i],path[i-1],{255,255,0})
    
        end
    
      end

  end
  

  path = {}

  if target and not self.path then
    
    path[1] = mcontroller.position()
  
    local targetPosition = world.entityPosition(target)
    
    local step  = self.step
    
    local xDist = targetPosition[1] - path[1][1]
    
    local xDir  = xDist > 0 and 1 or -1
    
    local yDist = targetPosition[2] - path[1][2]
    
    local yDir  = yDist > 0 and 1 or - 1
    
    local targetHorizon = {{targetPosition[1]-100,targetPosition[2]},{targetPosition[1]+100,targetPosition[2]}}

    local approachAngle = vec2.angle({xDir, math.sin(xDir) * self.waveHeight * yDir * xDir })

    local origin = vec2.intersect(targetHorizon[1], targetHorizon[2], path[1], vec2.add(path[1],vec2.withAngle(approachAngle,100)))
  
    --util.debugLine(targetHorizon[1],targetHorizon[2],{255,255,0})

    --util.debugLine(path[1],vec2.add(path[1],vec2.withAngle(approachAngle,100)),{255,0,255})

    util.debugPoint(origin,{255,255,0})

    if origin then 
  
      for x = 0, xDist, xDir do
  
        local point = {x, math.sin(x * xDir)*self.waveHeight * yDir}
  
        table.insert(path,vec2.add(point,origin))
  
      end
  
    end
  
    if #path > 1 then
  
      for i = 2, #path do
  
        util.debugLine(path[i],path[i-1],{0,255,255})
  
      end
  
    end

  end

end