/* * PROJECT: Traffic Light Controller (Classical Alloy Version)
 * DESCRIPTION: This model uses a 'State' signature to represent the DFA transitions.
 */

// --- 1. SIGNATURES ---
abstract sig Color {}
one sig RED, GREEN extends Color {}

// We represent the timeline as a set of States
sig State {
   colorA: one Color,
   colorB: one Color,
   next: lone State // Links one state to the next (DFA transition)
}

// Ensure there is exactly one starting state (no incoming transitions)
one sig InitialState extends State {}
fact {
   no s: State | s.next = InitialState
}

// --- 2. TRANSITIONS (The DFA Logic) ---

// Initial condition: Both lights are RED
fact Init {
   InitialState.colorA = RED
   InitialState.colorB = RED
}

// Transition Rules: Define how colorA and colorB change between state 's' and 's.next'
fact Transitions {
   all s: State | some s.next implies {
      // Rule: Only one light can change at a time (simplified)
      (s.colorA != s.next.colorA implies s.colorB = s.next.colorB)
      and
      (s.colorB != s.next.colorB implies s.colorA = s.next.colorA)
   }
}

/* * LINEAR TIME FACT:
 * This forces Alloy to generate a single, linear execution trace (a path).
 * This makes the visualizer look like a step-by-step state machine.
 */
fact LinearTime {
   // Every state has at most one 'next' state (no branching)
   all s: State | lone s.next 
   
   // There is exactly one state that acts as the "end" of the trace
   one s: State | no s.next 
   
   // Prevent "orphan" states: every state must be reachable from the start
   all s: State | s = InitialState or InitialState in s.^next
}
// --- 3. PROPERTIES (To be verified) ---

// Safety: "Both lights are never GREEN at the same time"
assert neverCrash {
   all s: State | !(s.colorA = GREEN and s.colorB = GREEN)
}

// Liveness: "If a light is RED, there is a future state where it is GREEN"
assert eventuallyGreen {
   all s: State | s.colorA = RED implies (some future: s.^next | future.colorA = GREEN)
}

// --- 4. COMMANDS ---

// Check safety: This will likely fail (Counterexample) because our 
// transitions don't explicitly forbid moving to a (GREEN, GREEN) state.
check neverCrash for 5 State

// Generate a visual representation of the state machine
run {} for 5 State

