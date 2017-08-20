require "/scripts/util.lua"
function init()
  gameCanvas = widget.bindCanvas("scriptCanvas")
  widget.focus("scriptCanvas")
  self.state = FSM:new()
  self.state:set(menu)
end

input = {
  key = {
    up = 87,
    down = 88,
    w = 65,
    s = 61
  },
  up = false,
  down = false,
  w = false,
  s = false
}

function menu()
  gameCanvas:clear()
  gameCanvas:drawText("PONG",{position={195, 201}, horizontalAnchor="mid", verticalAnchor="top"},36,{255,255,255})
  gameCanvas:drawImage("/objects/generic/pong/start.png",{169,98},1)
  isMenu = true
  while true do
    coroutine.yield()
  end
end

function resetball()
time = 30
posb = {x=195,y=105,angle=math.random(0,1)*180,dis=2.5}
end
function startgame()
  isMenu = false
  scorel = 0
  scorer = 0
  posl = 85
  posr = 85
  resetball()
end

function draw()
  gameCanvas:clear()
  gameCanvas:drawText(scorel,{position={195, 201}, horizontalAnchor="right", verticalAnchor="top"},24,{255,255,255})
  gameCanvas:drawText(scorer,{position={198, 201}, horizontalAnchor="left", verticalAnchor="top"},24,{255,255,255})
  gameCanvas:drawLine({195,210},{195,0},{255,255,255},2)
  gameCanvas:drawRect({0,200,390,210},{255,255,255})
  gameCanvas:drawRect({0,0,390,10},{255,255,255})
  gameCanvas:drawRect({10,posl,20,posl+40},{255,255,255})
  gameCanvas:drawRect({370,posr,380,posr+40},{255,255,255})
  gameCanvas:drawRect({util.round(posb.x)-5,util.round(posb.y)-5,util.round(posb.x)+5,util.round(posb.y)+5},{255,255,255})
end

function bounce(dir,angle)
  local dir = angle*2-dir
  return dir-360*math.floor(dir/360)
end
function renderball(posx,posy)
  gameCanvas:drawRect({posx-5,posy-5,posx+5,posy+5},{255,255,255})
end
function update(dt)
  self.state:update(dt)
end
function game()
  while true do
  util.wait(3,function()
    if posb.y < posr + 5 then
      posr = posr - 3
    elseif posb.y > posr + 35 then
      posr = posr + 3
    end
    if input.up or input.w then
	  posl = posl + 3
    end
    if input.down or input.s then
      posl = posl - 3
    end
	posl = math.max(10,posl)
    posl = math.min(160,posl)
	draw()
  end)
  while true do
    if posb.x <= 25 and posb.x >= 25-posb.dis and posl >= posb.y-42.5 and posl <= posb.y+2.5 then
      local newangle = ((posb.y-posl-20)*3+(90*2-posb.angle))/2
	  posb.angle = newangle-360*math.floor(newangle/360)
      posb.x = 25
	  posb.dis = posb.dis + 0.1
	  pane.playSound("/objects/generic/pong/paddle.ogg")
    elseif posb.x >= 365 and posb.x <= 365+posb.dis and posr >= posb.y-42.5 and posr <= posb.y+2.5 then
	  posb.angle = (bounce((posb.y-posr-20)*3,90)+bounce(posb.angle,90))/2
	  posb.x = 365
	  posb.dis = posb.dis + 0.1
	  pane.playSound("/objects/generic/pong/paddle.ogg")
    end
    if posb.y < posr + 5 then
      posr = posr - 2
    elseif posb.y > posr + 35 then
      posr = posr + 2
    end
    if input.up or input.w then
	  posl = posl + 2
    end
    if input.down or input.s then
      posl = posl - 2
    end
    posl = math.max(10,posl)
    posl = math.min(160,posl)
    posr = math.max(10,posr)
    posr = math.min(160,posr)
    if posb.y <= 15 then
      posb.y = 15
      posb.angle = bounce(posb.angle,0)
	  pane.playSound("/objects/generic/pong/wall.ogg")
    elseif posb.y >= 195 then
      posb.y = 195
      posb.angle = bounce(posb.angle,0)
	  pane.playSound("/objects/generic/pong/wall.ogg")
    end
    if posb.x <= posb.dis*-10 then
	  scorer = scorer+1
	  resetball()
	  pane.playSound("/objects/generic/pong/score.ogg")
	  draw()
	  if scorer == 10 then
        gameCanvas:drawText("PLAYER 2 WINS!",{position={195, 181}, horizontalAnchor="mid", verticalAnchor="top"},36,{255,255,255})
	    util.wait(3)
	    self.state:set(menu)
	  else
	    break
	  end
    elseif posb.x >= posb.dis*10+390 then
      scorel = scorel+1
	  resetball()
	  pane.playSound("/objects/generic/pong/score.ogg")
	  draw()
	  if scorel == 10 then
        gameCanvas:drawText("PLAYER 1 WINS!",{position={195, 181}, horizontalAnchor="mid", verticalAnchor="top"},36,{255,255,255})
	    util.wait(3)
	    self.state:set(menu)
	  else
	    break
	  end
	  break
    end
    posb.x = posb.x + posb.dis * math.cos(posb.angle*(math.pi/180))
    posb.y = posb.y + posb.dis * math.sin(posb.angle*(math.pi/180))
	draw()
	coroutine.yield()
  end
  end
end
function canvasKeyEvent(key, isKeyDown)
  if key == input.key.up then
    input.up = isKeyDown
  end
  if key == input.key.down then
    input.down = isKeyDown
  end
  if key == input.key.w then
    input.w = isKeyDown
  end
  if key == input.key.s then
    input.s = isKeyDown
  end
end
function canvasClickEvent(pos,button,isButtonDown)
  if button == 0 and pos[1] > 171 and pos[1] < 219 and pos[2] > 98 and pos[2] < 112 and isMenu then
	startgame()
    self.state:set(game)
  end
end
