extends Node

## Per-round statistics tracker.

signal stats_updated()

var dive_count: int = 0
var total_earnings: int = 0
var best_dive_earnings: int = 0


func record_dive(earnings: int) -> void:
	dive_count += 1
	total_earnings += earnings
	if earnings > best_dive_earnings:
		best_dive_earnings = earnings
	stats_updated.emit()


func get_rating() -> String:
	if total_earnings >= 150:
		return "豐收"
	elif total_earnings >= 80:
		return "不錯"
	else:
		return "繼續努力"


func reset() -> void:
	dive_count = 0
	total_earnings = 0
	best_dive_earnings = 0
