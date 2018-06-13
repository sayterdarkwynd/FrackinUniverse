require '/scripts/util.lua'
require '/scripts/vec2.lua'

function init()
  gameCanvas = widget.bindCanvas('scriptCanvas')
  widget.focus('scriptCanvas')
  self.state = FSM:new()
  self.state:set(menu)
end

input = {
  key = {
    up = 87,
    down = 88,
    w = 65,
    s = 61,
	k = 53,
	e = 47,
	v = 64,
	i = 51,
	n = 56
  },
  up = false,
  down = false,
  w = false,
  s = false,
  k = false,
  e = false,
  v = false,
  i = false,
  n = false
}

function menu()
  secret = forceSecret or math.random(1,100) == 1
  gameCanvas:clear()
  gameCanvas:drawText('PONG',{position={195, 201}, horizontalAnchor='mid', verticalAnchor='top'},36,{255,255,255})
  gameCanvas:drawImage('/objects/generic/pong/start.png',{169,98},1)
  if secret then
    gameCanvas:drawImage('/objects/generic/pong/kevinmenu.png',{0,0})
  end
  isMenu = true
  while true do
    coroutine.yield()
  end
end

function resetball()
speed = 2.5
ballPos = {195,105}
ballVec = {-speed+math.random(0,1)*speed*2,0}
end
function startgame()
  isMenu = false
  leftscore = 0
  rightscore = 0
  leftpaddle = 105
  rightpaddle = 105
  resetball()
end

function draw()
  gameCanvas:clear()
  gameCanvas:drawText(leftscore,{position={195, 201}, horizontalAnchor='right', verticalAnchor='top'},24,{255,255,255})
  gameCanvas:drawText(rightscore,{position={198, 201}, horizontalAnchor='left', verticalAnchor='top'},24,{255,255,255})
  gameCanvas:drawLine({195,210},{195,0},{255,255,255},2)
  gameCanvas:drawRect({0,200,390,210},{255,255,255})
  gameCanvas:drawRect({0,0,390,10},{255,255,255})
  gameCanvas:drawRect({10,leftpaddle-20,20,leftpaddle+20},{255,255,255})
  gameCanvas:drawRect({370,rightpaddle-20,380,rightpaddle+20},{255,255,255})
  if secret then
    gameCanvas:drawImage('/objects/generic/pong/kevin.png', {util.round(ballPos[1])-6.5,util.round(ballPos[2])-6.5}, 1)
  else
    gameCanvas:drawRect({util.round(ballPos[1])-5,util.round(ballPos[2])-5,util.round(ballPos[1])+5,util.round(ballPos[2])+5},{255,255,255})
  end
end

function update(dt)
  self.state:update(dt)
end
function game()
  while true do
    util.wait(3,function()
      if ballPos[2] < rightpaddle - 15 then
        rightpaddle = rightpaddle - 2
      elseif ballPos[2] > rightpaddle + 15 then
        rightpaddle = rightpaddle + 2
      end
      if (input.up or input.w) and not (input.down or input.s) then
	    leftpaddle = math.min(leftpaddle + 2,180)
      elseif (input.down or input.s) and not (input.up or input.w) then
        leftpaddle = math.max(leftpaddle - 2,30)
      end
	  draw()
    end)
    while true do
	  if ballPos[2] < rightpaddle - 15 then
        rightpaddle = rightpaddle - 2
      elseif ballPos[2] > rightpaddle + 15 then
        rightpaddle = rightpaddle + 2
      end
      if (input.up or input.w) and not (input.down or input.s) then
	    leftpaddle = math.min(leftpaddle + 2,180)
      elseif (input.down or input.s) and not (input.up or input.w) then
        leftpaddle = math.max(leftpaddle - 2,30)
      end
	  local tempVec = vec2.add(ballVec,0)
	  while true do
	    if ballPos[1] > 25 and ballPos[1] + tempVec[1] <= 25 and tempVec[1] ~= 0 and not (ballPos[2] + tempVec[2] * ((ballPos[1] - 25) / math.abs(tempVec[1])) < 15 or ballPos[2] + tempVec[2] * ((ballPos[1] - 25) / math.abs(tempVec[1])) > 195) then
	      local mult = (ballPos[1] - 25) / math.abs(tempVec[1])
		  ballPos = {25,ballPos[2] + tempVec[2] * mult}
		  if math.abs(ballPos[2]-leftpaddle) < 25 then
		    speed = speed + 0.1
		    local newMult = (speed + 0.1) / speed
		    local rotation = ((ballPos[2]-leftpaddle)*(math.pi/60)+(vec2.angle({tempVec[1]*-1,tempVec[2]})+math.pi)%(math.pi*2)-math.pi)/2
		    tempVec = vec2.mul(vec2.rotate(tempVec,-vec2.angle(tempVec)+rotation),(1-mult)*newMult)
		    ballVec = vec2.mul(vec2.rotate(ballVec,-vec2.angle(ballVec)+rotation),newMult)
			pane.playSound('/objects/generic/pong/paddle.ogg')
		  end
	    elseif ballPos[1] < 365 and ballPos[1] + tempVec[1] >= 365 and tempVec[1] ~= 0 and not (ballPos[2] + tempVec[2] * ((365 - ballPos[1]) / tempVec[1]) < 15 or ballPos[2] + tempVec[2] * ((365 - ballPos[1]) / tempVec[1]) > 195) then
	      local mult = (365 - ballPos[1]) / tempVec[1]
		  ballPos = {365,ballPos[2] + tempVec[2] * mult}
		  if math.abs(ballPos[2]-rightpaddle) < 25 then
		    speed = speed + 0.1
		    local newMult = (speed + 0.1) / speed
		    local rotation = ((ballPos[2]-rightpaddle)*(math.pi/60)*-1+vec2.angle({tempVec[1]*-1,tempVec[2]})-math.pi)/2
		    tempVec = vec2.mul(vec2.rotate(tempVec,-vec2.angle(tempVec)+math.pi+rotation),(1-mult)*newMult)
		    ballVec = vec2.mul(vec2.rotate(ballVec,-vec2.angle(ballVec)+math.pi+rotation),newMult)
			pane.playSound('/objects/generic/pong/paddle.ogg')
		  end
	    elseif ballPos[2] + tempVec[2] <= 15 then
		  local mult = (ballPos[2] - 15) / math.abs(tempVec[2])
		  ballPos = {ballPos[1] + tempVec[1] * mult,15}
		  tempVec = {tempVec[1],tempVec[2]*-1}
		  ballVec = {ballVec[1],ballVec[2]*-1}
		  pane.playSound('/objects/generic/pong/wall.ogg')
		elseif ballPos[2] + tempVec[2] >= 195 then
		  local mult = (195 - ballPos[2]) / tempVec[2]
		  ballPos = {ballPos[1] + tempVec[1] * mult,195}
		  tempVec = {tempVec[1],tempVec[2]*-1}
		  ballVec = {ballVec[1],ballVec[2]*-1}
		  pane.playSound('/objects/generic/pong/wall.ogg')
		else
	      ballPos = vec2.add(ballPos,tempVec)
		  break
		end
	  end
	  if ballPos[1] <= -100 then
	    rightscore = rightscore+1
	    resetball()
	    pane.playSound('/objects/generic/pong/score.ogg')
	    draw()
	    if rightscore == 10 then
          gameCanvas:drawText('PLAYER 2 WINS!',{position={195, 181}, horizontalAnchor='mid', verticalAnchor='top'},36,{255,255,255})
	      util.wait(3)
	      self.state:set(menu)
	    else
	      break
	    end
      elseif ballPos[1] >= 490 then
        leftscore = leftscore+1
	    resetball()
	    pane.playSound('/objects/generic/pong/score.ogg')
	    draw()
	    if leftscore == 10 then
          gameCanvas:drawText('PLAYER 1 WINS!',{position={195, 181}, horizontalAnchor='mid', verticalAnchor='top'},36,{255,255,255})
	      util.wait(3)
	      self.state:set(menu)
	    else
	      break
	    end
	  else
	    draw()
	  end
	  coroutine.yield()
    end
  end
end
function canvasKeyEvent(key, isKeyDown)
  if key == input.key.up then
    input.up = isKeyDown
  elseif key == input.key.down then
    input.down = isKeyDown
  elseif key == input.key.w then
    input.w = isKeyDown
  elseif key == input.key.s then
    input.s = isKeyDown
  elseif key == input.key.k then
    input.k = isKeyDown
  elseif key == input.key.e then
    input.e = isKeyDown
  elseif key == input.key.v then
    input.v = isKeyDown
  elseif key == input.key.i then
    input.i = isKeyDown
  elseif key == input.key.n then
    input.n = isKeyDown
  end
  if (key == input.key.k or key == input.key.e or key == input.key.v or key == input.key.i or key == input.key.n) and input.k and input.e and input.v and input.i and input.n then
    forceSecret = true
    self.state:set(menu)
  end
end
function canvasClickEvent(pos,button,isButtonDown)
  if button == 0 and pos[1] > 171 and pos[1] < 219 and pos[2] > 98 and pos[2] < 112 and isMenu then
	startgame()
    self.state:set(game)
  end
end
