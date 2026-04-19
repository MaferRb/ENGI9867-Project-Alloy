/**
 * Traffic Light Controller — Alloy 6 Model
 *
 * Two traffic lights at an intersection:
 *   ns = North-South light
 *   ew = East-West light
 * Each light has three colors: Red, Green, Yellow.
 * Uses Alloy 6 temporal operators: var, always, after.
 */

enum Color { Red, Green, Yellow }

one sig Intersection {
  var ns: one Color,   -- North-South traffic light
  var ew: one Color    -- East-West traffic light
}

-- Initial state: NS starts green, EW starts red
fact Init {
  Intersection.ns = Green
  Intersection.ew = Red
}

-- Transition cycle: (Green,Red) -> (Yellow,Red) -> (Red,Green) -> (Red,Yellow) -> ...
fact Transitions {
  always (
    ((Intersection.ns = Green  and Intersection.ew = Red)    =>
      (after Intersection.ns = Yellow and after Intersection.ew = Red))    and
    ((Intersection.ns = Yellow and Intersection.ew = Red)    =>
      (after Intersection.ns = Red    and after Intersection.ew = Green))  and
    ((Intersection.ns = Red    and Intersection.ew = Green)  =>
      (after Intersection.ns = Red    and after Intersection.ew = Yellow)) and
    ((Intersection.ns = Red    and Intersection.ew = Yellow) =>
      (after Intersection.ns = Green  and after Intersection.ew = Red))
  )
}

-- ============================================================
-- SAFETY 1: both lights are never green at the same time
-- Expected: NO counterexample (passes)
-- ============================================================
assert NeverBothGreen {
  always not (Intersection.ns = Green and Intersection.ew = Green)
}

-- ============================================================
-- SAFETY 2: after NS green, NS always goes to yellow (not red)
-- Expected: NO counterexample (passes)
-- ============================================================
assert NSGreenFollowedByNSYellow {
  always (Intersection.ns = Green => after Intersection.ns = Yellow)
}

-- ============================================================
-- REACHABILITY: from NS green, EW gets green in exactly 2 steps
-- Expected: NO counterexample (passes)
-- ============================================================
assert EWGetsGreenIn2Steps {
  always (Intersection.ns = Green => after after Intersection.ew = Green)
}

-- ============================================================
-- COUNTEREXAMPLE: claims NS green leads directly to EW green
-- Expected: COUNTEREXAMPLE FOUND (fails)
-- Alloy will show: ns=Green,ew=Red -> after ns=Yellow,ew=Red (not ew=Green)
-- ============================================================
assert NSGreenDirectlyToEWGreen {
  always (Intersection.ns = Green => after Intersection.ew = Green)
}

check NeverBothGreen            for 10  -- safety 1
check NSGreenFollowedByNSYellow for 10  -- safety 2
check EWGetsGreenIn2Steps       for 10  -- reachability
check NSGreenDirectlyToEWGreen  for 10  -- counterexample

run ShowTrace {} for 10
