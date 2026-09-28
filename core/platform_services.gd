class_name PlatformServices
extends Node
## Explicit local adapter boundaries. No network, purchases, ads or analytics by default.

signal event_logged(name: String, payload: Dictionary)
var analytics_enabled: bool = false

func log_event(event_name: String, payload: Dictionary = {}) -> void:
	if analytics_enabled:
		event_logged.emit(event_name, payload.duplicate(true))

func billing_available() -> bool:
	return false

func rewarded_ads_available() -> bool:
	return false

func purchase(_product_id: String) -> Dictionary:
	return {"ok": false, "available": false, "error": "Billing is unavailable in this local build."}

func show_rewarded_ad() -> Dictionary:
	return {"ok": false, "available": false, "rewarded": false, "error": "Rewarded ads are unavailable in this local build."}

func leaderboard_status() -> Dictionary:
	return {"available": false, "scope": "local", "message": "Records are stored on this device."}
