require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
	localAnimator.clearDrawables()
    for _,l in pairs(animationConfig.animationParameter("lineList", {})) do
		localAnimator.addDrawable({line = l.line, width = l.width, color = l.color, position = l.position, fullbright = true})
    end
end
