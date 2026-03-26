extends Node

## Autoload singleton — loads all ItemData resources from data/items/ on startup
## and provides query methods for other systems.

const _ITEMS_PATH: String = "res://data/items/"

var _items_by_id: Dictionary = {}
var _all_items: Array = []


func _ready() -> void:
	_load_all_items()


func get_by_id(id: String) -> Resource:
	return _items_by_id.get(id, null)


func get_by_category(category: int) -> Array:
	var result: Array = []
	for item in _all_items:
		if item.category == category:
			result.append(item)
	return result


func get_by_rarity(rarity: int) -> Array:
	var result: Array = []
	for item in _all_items:
		if item.rarity == rarity:
			result.append(item)
	return result


func get_by_depth(depth: float) -> Array:
	var result: Array = []
	for item in _all_items:
		if item.is_valid_at_depth(depth):
			result.append(item)
	return result


func get_all() -> Array:
	return _all_items.duplicate()


func _load_all_items() -> void:
	_all_items.clear()
	_items_by_id.clear()

	var sub_dirs: Array = ["metals", "junk", "relics", "chests"]
	for sub_dir in sub_dirs:
		_load_from_directory(_ITEMS_PATH + sub_dir + "/")

	print("ItemDatabase: loaded %d items." % _all_items.size())


func _load_from_directory(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return  # Directory doesn't exist yet, that's OK

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			_load_item(dir_path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_item(res_path: String) -> void:
	var resource: Resource = load(res_path)
	if resource == null:
		return

	if resource.get("id") == null or resource.id.is_empty():
		return

	_items_by_id[resource.id] = resource
	_all_items.append(resource)
