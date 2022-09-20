/*
 * author: Phlarx
 */

namespace CP {
	/**
	 * CP::apiVersion
	 * This value will be incremented for any changes that add, remove, or
	 * otherwise change the functional interface of this API.
	 */
	const int apiVersion = 1;
	
	/**
	 * CP::inGame
	 * If true, then this plugin has detected that we are in game, on a map.
	 * If false, none of the other values are valid.
	 */
	import bool get_inGame() const property from "CP";

	/**
	 * CP::strictMode
	 * If false, then at least one checkpoint tag is a non-standard value.
	 * Only applies to NEXT and MP4.
	 */
	import bool get_strictMode() const property from "CP";

	/**
	 * CP::curMapId
	 * The ID of the map whose checkpoints have been counted.
	 */
	import string get_curMapId() const property from "CP";

	/**
	 * CP::curCP
	 * The number of checkpoints completed in the current lap.
	 */
	import uint get_curCP() const property from "CP";

	/**
	 * CP::curCPLapTime
	 * The time value of the most recently completed checkpoint within the current lap.
	 */
	import int get_curCPLapTime() const property from "CP";

	/**
	 * CP::curCPRaceTime
	 * The time value of the most recently completed checkpoint within the current race.
	 */
	import int get_curCPRaceTime() const property from "CP";

	/**
	 * CP::curLap
	 * The number of laps completed in the current race.
	 */
	import uint get_curLap() const property from "CP";

	/**
	 * CP::maxCP
	 * The number of checkpoints detected for the current map, in a single lap.
	 */
	import uint get_maxCP() const property from "CP";

	/**
	 * CP::maxLap
	 * The number of laps detected for the current map.
	 */
	import uint get_maxLap() const property from "CP";
}
