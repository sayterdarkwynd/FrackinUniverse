local function lerp(a, b, t)
  return a + (b-a) * t
end

-- Domain: x[a->b]
-- Range:   [0->1]
local function inverseLerp(a, b, x)
  return (x-a)/(b-a)
end

-- Domain: [in1  ->  in2], t[0->1]
-- Range:  [out1 -> out2]
local function remap(in1, in2, out1, out2, x)
  return lerp(out1, out2, inverseLerp(in1, in2, x))
end

function init()
	script.setUpdateDelta(10)
	healthMin=config.getParameter("healthMin",0.1)
	healthMax=config.getParameter("healthMax",1.0)
	multMin=config.getParameter("multMin",1.0)
	multMax=config.getParameter("multMax",0.1)
	effectHandler=effect.addStatModifierGroup({})
end

function update(dt)
	effect.setStatModifierGroup(effectHandler,{{stat="protection",effectiveMultiplier=remap(healthMin,healthMax,multMin,multMax,math.max(math.min(status.resourcePercentage("health"),healthMax),healthMin))}})
end

function uninit()
	effect.removeStatModifierGroup(effectHandler)
end
