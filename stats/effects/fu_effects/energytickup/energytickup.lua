function init()
	fTickRate = config.getParameter("tickRate", 60)
	fTickAmount = config.getParameter("tickAmount", 1)
	script.setUpdateDelta(fTickRate)
end

function update(dt)
		status.modifyResource("energy", fTickAmount)
end

function uninit()

end
