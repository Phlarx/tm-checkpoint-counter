/*
 * author: Phlarx
 */

namespace CP {
	bool _inGame = false;
	bool _strictMode = true;
	string _curMapId = "";
	uint _curCP = 0;
	int _curCPLapTime = 0;
	int _curCPRaceTime = 0;
	uint _curLap = 0;
	uint _maxCP = 0;
	uint _maxLap = 0;
	
	bool get_inGame() property { return _inGame; }
	bool get_strictMode() property { return _strictMode; }
	string get_curMapId() property { return _curMapId; }
	uint get_curCP() property { return _curCP; }
	int get_curCPLapTime() property { return _curCPLapTime; }
	int get_curCPRaceTime() property { return _curCPRaceTime; }
	uint get_curLap() property { return _curLap; }
	uint get_maxCP() property { return _maxCP; }
	uint get_maxLap() property { return _maxLap; }
	
#if TMNEXT
	uint _preCPIdx = 0;
	uint _preLapStartTime = 0;
#endif
	
	void Main() {
#if TMNEXT && DEPENDENCY_PLAYERSTATE
		print("CheckpointCounter lib is using PlayerState for checkpoint data");
#elif TMNEXT
		print("CheckpointCounter lib is not using PlayerState for checkpoint data");
#endif
	}
	
	/*
	 * Update detects map changes, and re-counts CPs when it occurs.
	 * Additionally, it updates the CP/Lap info while a race is underway.
	 */
	void Update() {
#if TMNEXT
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		
		if(playground is null
			|| playground.Arena is null
			|| playground.Map is null
			|| playground.GameTerminals.Length <= 0
			|| playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing
			|| cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
			_inGame = false;
			return;
		}
		
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		auto scriptPlayer = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
		
		if(scriptPlayer is null) {
			_inGame = false;
			return;
		}
		
		if(player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
			// sadly, can't see CPs of spectated players any more
			_inGame = false;
			return;
		}
		
		MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;
		
		if(!_inGame && (_curMapId != playground.Map.IdName || GetApp().Editor !is null)) {
			// keep the previously-determined CP data, unless in the map editor
			_curMapId = playground.Map.IdName;
			_curCP = 0;
			_maxCP = 0;
			_curLap = 0;
			_maxLap = playground.Map.TMObjective_IsLapRace ? playground.Map.TMObjective_NbLaps : 1;
			_strictMode = true;
			
			array<int> links = {};
			for(uint i = 0; i < landmarks.Length; i++) {
				if(landmarks[i].Waypoint !is null && !landmarks[i].Waypoint.IsFinish && !landmarks[i].Waypoint.IsMultiLap) {
					// we have a CP, but we don't know if it is Linked or not
					if(landmarks[i].Tag == "Checkpoint") {
						_maxCP += 1;
					} else if(landmarks[i].Tag == "LinkedCheckpoint") {
						if(links.Find(landmarks[i].Order) < 0) {
							_maxCP += 1;
							links.InsertLast(landmarks[i].Order);
						}
					} else {
						// this waypoint looks like a CP, acts like a CP, but is not called a CP.
						if(_strictMode) {
							warn("The current map, " + string(playground.Map.MapName) + " (" + playground.Map.IdName + "), is not compliant with checkpoint naming rules."
									+ " If the CP count for this map is inaccurate, please report this map on the GitHub issues page:"
									+ " https://github.com/Phlarx/tm-checkpoint-counter/issues");
						}
						_maxCP += 1;
						_strictMode = false;
					}
				}
			}
		}
		_inGame = true;
		
#if DEPENDENCY_PLAYERSTATE
		// PlayerState is heavier, but allows detecting multiple CPs in one frame, as well as getting lap times
		if(PlayerState::GetRaceData().PlayerState == PlayerState::EPlayerState::EPlayerState_Driving) {
			auto info = PlayerState::GetRaceData().dPlayerInfo;
			_curCP = info.NumberOfCheckpointsPassed;
			if(info.LatestCPTime > 0) {
				// LatestCPTime currently only exists for 1 frame
				_curCPLapTime = info.LatestCPTime - info.LapStartTime;
				_curCPRaceTime = info.LatestCPTime;
			}
			_curLap = info.CurrentLapNumber;
		} else {
			_curCP = 0;
			_curCPLapTime = 0;
			_curCPRaceTime = 0;
			_curLap = 0;
		}
#else
		// The original method
		if(_preCPIdx != player.CurrentLaunchedRespawnLandmarkIndex && landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
			_preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
			
			if(landmarks[_preCPIdx].Waypoint is null || landmarks[_preCPIdx].Waypoint.IsFinish || landmarks[_preCPIdx].Waypoint.IsMultiLap) {
				// if null, it's a start block. if the other flags, it's either a multilap or a finish.
				// in all such cases, we reset the completed cp count to zero.
				_curCP = 0;
			} else {
				_curCP++;
			}
		}
#endif
		
#elif TURBO
		auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
		auto playgroundScript = cast<CTrackManiaRaceRules>(GetApp().PlaygroundScript);
		
		if(playground is null
			|| playgroundScript is null
			|| playground.GameTerminals.Length <= 0
			|| cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer) is null) {
			_inGame = false;
			return;
		}
		
		auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);
		
		if(player is null
			|| player.CurLap is null
			|| player.RaceState != CTrackManiaPlayer::ERaceState::Running) {
			_inGame = false;
			return;
		}
		
		/* Turbo doesn't support linked checkpoints, so this is sufficient */
		_maxCP = playgroundScript.MapCheckpointPos.Length;
		_maxLap = playgroundScript.MapNbLaps;
		
		_inGame = true;
		
		/* Checkpoints gains the time value of each CP as it is passed */
		_curCP = player.CurLap.Checkpoints.Length;
		_curCPLapTime = player.CurLap.Checkpoints.Length > 0 ? player.CurLap.Checkpoints[player.CurLap.Checkpoints.Length - 1] : 0;
		_curCPRaceTime = player.CurRace.Checkpoints.Length > 0 ? player.CurRace.Checkpoints[player.CurRace.Checkpoints.Length - 1] : 0;
		_curLap = player.CurrentNbLaps;
		
#elif MP4
		auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
		auto rootMap = GetApp().RootMap;
		
		if(playground is null
			|| rootMap is null
			|| playground.GameTerminals.Length <= 0
			|| cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
			_inGame = false;
			return;
		}
		
		auto scriptPlayer = cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
		
		if(scriptPlayer is null
			|| scriptPlayer.CurLap is null
			|| scriptPlayer.RaceState != CTrackManiaPlayer::ERaceState::Running) {
			_inGame = false;
			return;
		}
		
		/* GetApp().PlaygroundScript.MapCheckpointPos.Length would be easier, but incorrect for linked CPs */
		
		if(!_inGame && (_curMapId != rootMap.IdName || GetApp().Editor !is null)) {
			// keep the previously-determined CP data, unless in the map editor
			_curMapId = rootMap.IdName;
			_curCP = 0;
			_maxCP = 0;
			_curLap = 0;
			_maxLap = rootMap.TMObjective_NbLaps;
			_strictMode = true;
			
			array<int> links = {};
			for(uint i = 0; i < rootMap.Blocks.Length; i++) {
				if(rootMap.Blocks[i].WaypointSpecialProperty !is null && rootMap.Blocks[i].BlockInfo !is null) {
					auto tag = rootMap.Blocks[i].WaypointSpecialProperty.Tag;
					auto type = rootMap.Blocks[i].BlockInfo.WaypointType;
					if(type == CGameCtnBlockInfo::EWayPointType::Checkpoint) {
						// we have a CP, but we don't know if it is Linked or not
						if(tag == "Checkpoint" || tag == "Goal") {
							_maxCP++;
						} else if(tag == "LinkedCheckpoint") {
							if(links.Find(rootMap.Blocks[i].WaypointSpecialProperty.Order) < 0) {
								_maxCP++;
								links.InsertLast(rootMap.Blocks[i].WaypointSpecialProperty.Order);
							}
						} else {
							// this waypoint looks like a CP, acts like a CP, but is not called a CP.
							if(_strictMode) {
								warn("The current map, " + string(rootMap.MapName) + " (" + rootMap.IdName + "), is not compliant with checkpoint naming rules."
										+ " If the CP count for this map is inaccurate, please report this map on the GitHub issues page:"
										+ " https://github.com/Phlarx/tm-checkpoint-counter/issues");
							}
							_maxCP++;
							_strictMode = false;
						}
					}
				}
			}
			for(uint i = 0; i < rootMap.AnchoredObjects.Length; i++) {
				if(rootMap.AnchoredObjects[i].WaypointSpecialProperty !is null) {
					auto tag = rootMap.AnchoredObjects[i].WaypointSpecialProperty.Tag;
					auto type = rootMap.AnchoredObjects[i].ItemModel.WaypointType;
					if(type == CGameItemModel::EnumWaypointType::Checkpoint) {
						// we have a CP, but we don't know if it is Linked or not
						if(tag == "Checkpoint" || tag == "Goal") {
							_maxCP++;
						} else if(tag == "LinkedCheckpoint") {
							if(links.Find(rootMap.AnchoredObjects[i].WaypointSpecialProperty.Order) < 0) {
								_maxCP++;
								links.InsertLast(rootMap.AnchoredObjects[i].WaypointSpecialProperty.Order);
							}
						} else {
							// this waypoint looks like a CP, acts like a CP, but is not called a CP.
							if(_strictMode) {
								warn("The current map, " + string(rootMap.MapName) + " (" + rootMap.IdName + "), is not compliant with checkpoint naming rules."
										+ " If the CP count for this map is inaccurate, please report this map on the GitHub issues page:"
										+ " https://github.com/Phlarx/tm-checkpoint-counter/issues");
							}
							_maxCP++;
							_strictMode = false;
						}
					}
				}
			}
		}
		_inGame = true;
		
		/* Checkpoints gains the time value of each CP as it is passed */
		_curCP = scriptPlayer.CurLap.Checkpoints.Length;
		_curCPLapTime = Math::Max(0, scriptPlayer.CurCheckpointLapTime);
		_curCPRaceTime = Math::Max(0, scriptPlayer.CurCheckpointRaceTime);
		_curLap = scriptPlayer.CurrentNbLaps;
		
#endif
	}
}
