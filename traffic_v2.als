/* * Project: ENGI 9867 - Traffic Light Verification
 * Task: Safety Property Violation (Double Green)
 */

// 1. Define the elements of the system
abstract sig Color {}
one sig Red, Green extends Color {}

sig State {
    colorA: one Color,
    colorB: one Color,
    next: lone State
}

// 2. Initial state: Both lights must start at Red
fact Init {
    // Finds the state that has no predecessor
    let s0 = State - State.next |
    s0.colorA = Red and s0.colorB = Red
}

// 3. Faulty Transitions: This allows the "Double Green" bug
fact Transitions {
    all s: State, s': s.next | {
        // High-level rule: At least one light must change
        (s.colorA != s'.colorA) or (s.colorB != s'.colorB)
    }
}

// 4. Safety Property: "Never have both lights in Green at the same time"
assert neverCrash {
    all s: State | not (s.colorA = Green and s.colorB = Green)
}

// 5. Execution Command: Check for the violation
check neverCrash for 5 State
