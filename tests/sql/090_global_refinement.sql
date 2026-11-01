-- Global refinement SQL contract (plan 11 task 3).

DO $$
DECLARE
  valid_payload jsonb := '{
    "schemaVersion": 2,
    "source": "simulation",
    "completedPhases": ["A", "C", "B", "D"],
    "opponentLeads": {"sampleSize": 10, "leads": [{"id": "lead-0-1", "slots": [0,1], "count": 10}]},
    "leadPick": {"selection": {"ourFourSlots": [0,1,4,5], "ourLeadSlots": [0,1]}, "comparisons": [], "selectionRuleVersion": "selection-v1", "limitations": []},
    "openings": {"selection": {"ourFourSlots": [0,1,4,5], "ourLeadSlots": [0,1]}, "recommendationRule": "model-frequency-v1", "samplingPolicy": "conditional-back-v1", "byOpponentLead": []},
    "refinement": {
      "configuration": {"ourFourSlots": [0,1,4,5], "ourLeadSlots": [0,1]},
      "samplingPolicy": "weighted-ab",
      "samplingScope": "all-observed-leads",
      "sampleSize": 2,
      "outcomes": {"wins": 1, "losses": 1, "draws": 0},
      "scenarioCounts": [{"opponentLeadId": "lead-0-1", "opponentLeadSlots": [0,1], "opponentBackPair": [2,3], "count": 2}],
      "firstTurnSampleSize": 0,
      "firstTurns": [],
      "battleIds": ["b1", "b2"],
      "limitations": []
    },
    "gameplan": null,
    "winCondition": null
  }'::jsonb;
  legacy_payload jsonb;
BEGIN
  IF NOT core.is_valid_simulation_result_v2(valid_payload, false) THEN
    RAISE EXCEPTION 'expected valid global refinement payload';
  END IF;

  legacy_payload := jsonb_set(
    valid_payload,
    '{refinement}',
    '{"configuration": {"ourFourSlots": [0,1,4,5], "ourLeadSlots": [0,1]}, "sampleSize": 2, "outcomes": {"wins": 2, "losses": 0, "draws": 0}, "firstTurns": [], "battleIds": ["a","b"], "limitations": []}'::jsonb
  );

  IF core.is_valid_simulation_result_v2(legacy_payload, false) THEN
    RAISE EXCEPTION 'legacy refinement without samplingPolicy must be rejected';
  END IF;
END $$;
