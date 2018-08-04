
function init()
	widget.setText("textScrollBox.text", "Error initializing update info; Please report this error to the following mod with an attached log:\n"..tostring(status.statusProperty("zb_updatewindow_error", "ztarbound")))
end
