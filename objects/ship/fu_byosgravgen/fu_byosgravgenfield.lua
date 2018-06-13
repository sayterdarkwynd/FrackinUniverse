function init()
	status.setStatusProperty("fu_byosgravgenfield", status.statusProperty("fu_byosgravgenfield", 0) + 1)
end

function update(dt)
	
end

function uninit()
	status.setStatusProperty("fu_byosgravgenfield", status.statusProperty("fu_byosgravgenfield", 0) - 1)
end