@tool
class_name SongArtRounded
extends TextureRectRounded

# This subclass exists ONLY to share a single StyleBoxFlat across every
# instance used inside SongButtonCovered (or anywhere else you use THIS
# specific subclass), instead of each instance allocating its own.
#
# The base TextureRectRounded addon is left untouched, so every other
# place in the UI using TextureRectRounded directly keeps its own
# per-instance stylebox and can freely use different radius/detail values.
#
# IMPORTANT: every node using SongArtRounded (not TextureRectRounded)
# will share the exact same corner radius / corner_detail / anti_aliasing
# values. The first instance to run _ready() configures the shared style;
# after that, changing @export values on ONE instance in the editor will
# visually affect ALL instances using SongArtRounded. Only use this
# subclass where that's actually true (e.g. all song list art thumbnails).

static var shared_stylebox: StyleBoxFlat


func _ready():
	# Let the parent do its normal setup (clip_children, texture_rect
	# child creation, initial per-instance stylebox override, etc.)
	super._ready()

	# Lazily create the shared stylebox once, using whatever values
	# this first instance was configured with in the editor.
	if shared_stylebox == null:
		shared_stylebox = StyleBoxFlat.new()
		shared_stylebox.corner_radius_bottom_left = radius_bottom_left
		shared_stylebox.corner_radius_bottom_right = radius_bottom_right
		shared_stylebox.corner_radius_top_left = radius_top_left
		shared_stylebox.corner_radius_top_right = radius_top_right
		shared_stylebox.anti_aliasing = anti_aliasing
		shared_stylebox.corner_detail = corner_detail

	# Swap this instance's stylebox reference (inherited from
	# TextureRectRounded) to point at the shared one instead of the
	# per-instance one the parent's field initializer created.
	# The old per-instance StyleBoxFlat becomes unreferenced and is
	# freed shortly after — it was never used to draw anything since
	# we replace it here, before the first frame is rendered.
	stylebox = shared_stylebox
	add_theme_stylebox_override("panel", stylebox)
