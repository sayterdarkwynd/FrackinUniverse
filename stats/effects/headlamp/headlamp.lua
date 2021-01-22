require "/scripts/vec2.lua"
function init()
  script.setUpdateDelta(3)
end

function update(dt)
	animator.setFlipped(mcontroller.facingDirection() == -1)
	mouthPos=status.statusProperty("mouthPosition",{0,0.75})
	--"mouthPosition" : [0, 0.75]
	--[[
		{
			"lights" : {"glow" : {"active" : true,"position" : [1.5, 0.8],"color" : [50, 50, 50]},
			"beam" : {"active" : true,"position" : [0.8, 0.8],"color" : [190, 190, 190],"pointLight" : true,"pointAngle" : 0,"pointBeam" : 4.4}}
		}
	]]
	beamPos=vec2.add(mouthPos,{0.8,0.05})
	glowPos=vec2.add(mouthPos,{1.5,0.05})
	animator.setLightPosition("beam",beamPos)
	animator.setLightPosition("glow",glowPos)
end

function uninit()

end
