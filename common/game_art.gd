class_name GameArt
extends RefCounted

const PLAYER := preload("res://assets/art_samples/v01/player_mage.png")
const FLOOR := preload("res://assets/art_samples/v01/stone_floor.png")
const FIRE_ATLAS := preload("res://assets/art_samples/v01/fire_vfx_samples.png")
const TARGET := preload("res://assets/art/fire_v01/practice_target.png")
const ENEMY := preload("res://assets/art/fire_v01/soot_enemy.png")
const BURNING_GROUND := preload("res://assets/art/fire_v01/burning_ground.png")
const WORLD_SHADER := preload("res://vfx/world_art.gdshader")

static var _regions: Dictionary = {}
static var _shared_material: ShaderMaterial


static func apply_world_material(item: CanvasItem) -> void:
	item.material = world_material()
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	item.add_to_group("world_art")


static func world_material() -> ShaderMaterial:
	if _shared_material == null:
		_shared_material = actor_material()
	return _shared_material


static func actor_material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = WORLD_SHADER
	return result


static func trimmed(source: Texture2D) -> AtlasTexture:
	return _region(source, Rect2i(Vector2i.ZERO, Vector2i(source.get_size())))


static func fire(stage: int) -> AtlasTexture:
	var cell := Vector2i(FIRE_ATLAS.get_size()) / 2
	var origin := Vector2i(stage % 2, stage / 2) * cell
	return _region(FIRE_ATLAS, Rect2i(origin, cell))


static func _region(source: Texture2D, area: Rect2i) -> AtlasTexture:
	var key := source.resource_path + str(area)
	if _regions.has(key):
		return _regions[key]
	# Trim transparent padding once; the original artwork stays intact on disk.
	var bounds := source.get_image().get_region(area).get_used_rect()
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(bounds.position + area.position, bounds.size)
	texture.filter_clip = true
	_regions[key] = texture
	return texture
