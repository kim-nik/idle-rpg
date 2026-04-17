class_name AfkRewardService
extends RefCounted

const MIN_REWARD_SECONDS := 60
const MAX_REWARD_SECONDS := 8 * 60 * 60
const SECONDS_PER_MINUTE := 60

func queue_rewards(save_data: Dictionary, now_unix: int) -> Dictionary:
	var pending_gold = max(int(save_data.get("pending_afk_gold", 0)), 0)
	var pending_seconds = max(int(save_data.get("pending_afk_seconds", 0)), 0)
	var last_seen_unix = max(int(save_data.get("last_seen_unix", 0)), 0)

	var result := {
		"last_seen_unix": now_unix,
		"pending_afk_gold": pending_gold,
		"pending_afk_seconds": pending_seconds,
		"queued_gold": 0,
		"queued_seconds": 0,
		"did_change": now_unix != last_seen_unix
	}

	if now_unix <= 0:
		result.last_seen_unix = last_seen_unix
		result.did_change = false
		return result

	if last_seen_unix <= 0:
		return result

	var elapsed_seconds = mini(maxi(now_unix - last_seen_unix, 0), MAX_REWARD_SECONDS)
	if elapsed_seconds < MIN_REWARD_SECONDS:
		return result

	var reward_gold = calculate_gold_reward(
		max(int(save_data.get("campaign_chapter", 1)), 1),
		clampi(int(save_data.get("campaign_wave", 1)), 1, 10),
		elapsed_seconds
	)
	if reward_gold <= 0:
		return result

	result.pending_afk_gold = pending_gold + reward_gold
	result.pending_afk_seconds = pending_seconds + elapsed_seconds
	result.queued_gold = reward_gold
	result.queued_seconds = elapsed_seconds
	result.did_change = true
	return result

func calculate_gold_reward(chapter_number: int, wave_number: int, elapsed_seconds: int) -> int:
	var elapsed_minutes = int(floor(float(maxi(elapsed_seconds, 0)) / float(SECONDS_PER_MINUTE)))
	if elapsed_minutes <= 0:
		return 0

	var reward_per_minute = max(chapter_number, 1) * 100 + clampi(wave_number, 1, 10) * 25
	return elapsed_minutes * reward_per_minute
