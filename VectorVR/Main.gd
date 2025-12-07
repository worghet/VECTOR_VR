extends Node3D

var m_interfaceVr : XRInterface

##
## The headset position at program launch (not yet centered).
##
var m_transformVr : Transform3D

func _ready():
	initializeInterfaces()
	
func initializeInterfaces():
	m_interfaceVr = XRServer.find_interface("OpenXR")
	if m_interfaceVr and m_interfaceVr.is_initialized():
		##
		## Disabling VSync is broken for the Quest 3 OpenXR driver, so this will
		## generate an error and probably cause massive flickering.
		## But it's supposed to work, and will be fixed eventually.
		##
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		get_viewport().use_xr = true
		m_transformVr = XRServer.get_hmd_transform()
		m_interfaceVr.pose_recentered.connect(processOpenXrPoseRecentered)

func processOpenXrPoseRecentered():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT,true)
