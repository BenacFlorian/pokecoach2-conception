-- Phase E: complete simulation result with strengths-based gameplan.

SELECT core.is_valid_simulation_result_v2(
  '{
    "schemaVersion": 2,
    "source": "simulation",
    "completedPhases": ["A", "C", "B", "D", "synthesis"],
    "opponentLeads": {"sampleSize": 1, "leads": [{"id": "l", "slots": [0,1], "count": 1}]},
    "leadPick": {
      "selection": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "comparisons": [],
      "selectionRuleVersion": "c-v1",
      "limitations": []
    },
    "openings": {
      "selection": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "recommendationRule": "model-frequency-v1",
      "samplingPolicy": "conditional-back-v1",
      "byOpponentLead": []
    },
    "refinement": {
      "configuration": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "samplingPolicy": "weighted-ab",
      "samplingScope": "all-observed-leads",
      "sampleSize": 1,
      "outcomes": {"wins": 1, "losses": 0, "draws": 0},
      "scenarioCounts": [{"opponentLeadId": "l", "opponentLeadSlots": [0,1], "opponentBackPair": [2,3], "count": 1}],
      "firstTurnSampleSize": 0,
      "firstTurns": [],
      "battleIds": ["b1"],
      "limitations": []
    },
    "gameplan": {
      "opening": "o",
      "midgame": "m",
      "endgame": "e",
      "threats": [{"pokemon": {"side": "opponent", "slot": 0}, "explanation": "t"}],
      "strengths": [{"pokemon": {"side": "ours", "slot": 0}, "explanation": "s"}],
      "evidenceBattleIds": ["b1"]
    },
    "winCondition": {
      "description": "d",
      "rationale": "r",
      "evidenceBattleIds": ["b1"]
    }
  }'::jsonb,
  true
) AS valid_complete;

SELECT NOT core.is_valid_simulation_result_v2(
  '{
    "schemaVersion": 2,
    "source": "simulation",
    "completedPhases": ["A", "C", "B", "D", "synthesis"],
    "opponentLeads": {"sampleSize": 1, "leads": [{"id": "l", "slots": [0,1], "count": 1}]},
    "leadPick": {
      "selection": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "comparisons": [],
      "selectionRuleVersion": "c-v1",
      "limitations": []
    },
    "openings": {
      "selection": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "recommendationRule": "model-frequency-v1",
      "samplingPolicy": "conditional-back-v1",
      "byOpponentLead": []
    },
    "refinement": {
      "configuration": {"ourFourSlots": [0,1,2,3], "ourLeadSlots": [0,1]},
      "samplingPolicy": "weighted-ab",
      "samplingScope": "all-observed-leads",
      "sampleSize": 1,
      "outcomes": {"wins": 1, "losses": 0, "draws": 0},
      "scenarioCounts": [{"opponentLeadId": "l", "opponentLeadSlots": [0,1], "opponentBackPair": [2,3], "count": 1}],
      "firstTurnSampleSize": 0,
      "firstTurns": [],
      "battleIds": ["b1"],
      "limitations": []
    },
    "gameplan": {
      "opening": "o",
      "midgame": "m",
      "endgame": "e",
      "threats": [],
      "preserve": [],
      "eliminate": [],
      "adaptations": [],
      "evidenceBattleIds": ["b1"]
    },
    "winCondition": {
      "description": "d",
      "rationale": "r",
      "evidenceBattleIds": ["b1"]
    }
  }'::jsonb,
  true
) AS rejects_legacy_gameplan;
