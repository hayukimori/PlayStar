extends HybridWindow

@export var github_button: TextureButton
@export var bmc_button: TextureButton

const LINK_GITHUB: String = "https://github.com/hayukimori"
const LINK_BMC: String = "https://buymeacoffee.com/hayukimori"

func _ready() -> void:
	self.close_requested.connect(_close_request)
	if github_button: github_button.pressed.connect(_github_clicked)
	if bmc_button: bmc_button.pressed.connect(_bmc_clicked)


func _close_request() -> void:
	self.close()
	queue_free()


func _github_clicked() -> void:
	OS.shell_open(LINK_GITHUB)

func _bmc_clicked() -> void:
	OS.shell_open(LINK_BMC)
