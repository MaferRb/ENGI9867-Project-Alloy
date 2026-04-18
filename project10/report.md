# Model Checking a Traffic Light Controller with Alloy

---

## 1. Introduction

Model checking is a formal verification technique where a tool automatically explores every reachable state of a system to determine whether certain properties hold. Instead of relying on testing (which only covers some executions) or manual proofs (which are error-prone), model checking is exhaustive within a given scope: if a bug exists, the tool will find it and produce a concrete counterexample.

The connection to automata theory is pretty direct. In class we learned that a DFA is defined by a finite set of states, a start state, a transition function, and acceptance criteria. A model checker works on essentially the same idea — it takes a finite-state description of a system, builds the state graph, and checks properties over all possible execution paths. The system being checked *is* a finite automaton, and the model checker walks through it systematically.

For this project, I modeled a traffic light controller with two lights using Alloy, specified four properties (two safety, one reachability, and one intentionally false), and let the Alloy Analyzer verify them automatically.

---

## 2.Alloy

Alloy is the most approachable option. TLA+ and NuSMV both have steeper learning curves; TLA+ uses its own mathematical notation that requires time to get comfortable with, and NuSMV requires thinking in terms of SMV modules and CTL/LTL from the start. Alloy's syntax reads more like a declarative programming language, which made the initial setup less complex

Alloy also has a neat way of handling state sequences through its `util/ordering` module. You define a signature that represents time steps, import the ordering, and then you get functions like `first` and `next` that let you navigate through the trace. It is not as concise as having built-in temporal operators, but it is straightforward once you understand the pattern.

The Alloy Analyzer also has a visual interface that shows counterexamples as graphical traces, which helped a lot when debugging properties. And the documentation — especially Daniel Jackson's *Software Abstractions* and the material on alloytools.org — was solid enough to get me started without too much friction.

---

## 3. System Description

The system is a traffic light controller for a single intersection where a North-South (NS) road crosses an East-West (EW) road. There are **two traffic lights** — one for each direction — and each light can be Red, Green, or Yellow.

The controller follows a fixed cycle:

| Step | NS light | EW light |
|:---:|:---:|:---:|
| 1 | Green | Red |
| 2 | Yellow | Red |
| 3 | Red | Green |
| 4 | Red | Yellow |
| 5 | (back to step 1) | |

The idea is simple: NS gets its turn (green then yellow), then EW gets its turn (green then yellow), and the cycle repeats. At no point should both lights be green at the same time — that would mean cars from both directions can go, which is obviously dangerous.

The controller starts with NS green and EW red. There is no branching, no sensors, and no external input. Each step transitions deterministically to the next.

---

## 4. DFA Representation of the System

The traffic light controller has four reachable states — one for each combination of (NS color, EW color) that actually occurs. It maps directly to a DFA:

```
                ┌──────────────────────────────────────────────────┐
                │                                                  │
                ▼                                                  │
      ┌────────────────┐          ┌────────────────┐              │
 start│  NS:Green      │  tick    │  NS:Yellow     │              │
 ────►│  EW:Red        │ ───────► │  EW:Red        │              │
      └────────────────┘          └────────────────┘              │
                                         │                         │
                                         │ tick                    │
                                         ▼                         │
      ┌────────────────┐          ┌────────────────┐              │
      │  NS:Red        │  tick    │  NS:Red        │              │
      │  EW:Yellow     │ ◄─────── │  EW:Green      │              │
      └────────────────┘          └────────────────┘              │
                │                                                  │
                └──────────────────────────────────────────────────┘
                                    tick
```

The formal components of this DFA are:

- **States Q:** {(Green,Red), (Yellow,Red), (Red,Green), (Red,Yellow)} — each state is a pair (NS color, EW color)
- **Alphabet Σ:** {tick} — a single input symbol representing a clock pulse
- **Start state q₀:** (Green, Red)
- **Transition function δ:**

| Current state (NS, EW) | Input | Next state (NS, EW) |
|:---:|:---:|:---:|
| (Green, Red) | tick | (Yellow, Red) |
| (Yellow, Red) | tick | (Red, Green) |
| (Red, Green) | tick | (Red, Yellow) |
| (Red, Yellow) | tick | (Green, Red) |

- **Accepting states:** All states (the controller runs forever)

### Why this is a DFA and not an NFA

This system is a DFA because every state has **exactly one** outgoing transition for the single input symbol `tick`. Given the current combination of (NS color, EW color), the next combination is completely determined. An NFA would allow multiple possible next states for the same input, or ε-transitions that happen spontaneously. None of that applies here — the controller has no branching, no choices, and no non-determinism.

---

## 5. Alloy Model

Here is the complete Alloy 6 model. The state is represented by a single `Intersection` object with two `var` fields that change over time:

```alloy
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

-- Transition cycle
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
```

### How each part works

**`enum Color { Red, Green, Yellow }`** defines the three colors a traffic light can show.

**`one sig Intersection`** is a singleton — there is exactly one intersection. Its fields `ns` and `ew` are declared with `var`, which in Alloy 6 means they can change at each time step. This replaces the `sig Step` + `util/ordering` pattern from Alloy 5.

**`fact Init`** sets the initial values of `ns` and `ew` at time 0.

**`fact Transitions`** uses the `always` temporal operator to say that the transition rule holds at every time step. The `after` operator refers to the value of a field in the *next* time step. For example, the first implication reads: "it is always the case that if NS is Green and EW is Red, then after this step NS becomes Yellow and EW stays Red."

The correspondence to the DFA transition function δ:

```
δ(Green,Red)    = (Yellow,Red)   ↔  (ns=Green,  ew=Red)    => after(ns=Yellow, ew=Red)
δ(Yellow,Red)   = (Red,Green)    ↔  (ns=Yellow, ew=Red)    => after(ns=Red,    ew=Green)
δ(Red,Green)    = (Red,Yellow)   ↔  (ns=Red,    ew=Green)  => after(ns=Red,    ew=Yellow)
δ(Red,Yellow)   = (Green,Red)    ↔  (ns=Red,    ew=Yellow) => after(ns=Green,  ew=Red)
```

---

## 6. Properties to Verify

Defined four properties: two safety properties, one reachability property, and one intentionally false property.

### Property 1 — Safety: Both lights are never green at the same time

```alloy
assert NeverBothGreen {
  always not (Intersection.ns = Green and Intersection.ew = Green)
}
check NeverBothGreen for 10
```

This is the most important safety property for any intersection. It asserts that there is no step where both `ns` and `ew` are Green simultaneously. If this failed, it would mean two streams of traffic could collide. Since `ns` and `ew` are separate fields, Alloy actually has to verify that the transition constraints prevent this — it is not trivially true.

**Type:** Safety property — "something bad never happens."

### Property 2 — Safety: NS green is always followed by NS yellow

```alloy
assert NSGreenFollowedByNSYellow {
  always (Intersection.ns = Green => after Intersection.ns = Yellow)
}
check NSGreenFollowedByNSYellow for 10
```

This asserts that the yellow warning is never skipped. Whenever NS has a green light, the very next step must show yellow on NS — not a direct jump to red. In a real intersection, skipping the yellow warning would be dangerous.

**Type:** Safety property — ensures correct transition ordering.

### Property 3 — Reachability: EW gets green within 2 steps of NS green

```alloy
assert EWGetsGreenIn2Steps {
  always (Intersection.ns = Green => after after Intersection.ew = Green)
}
check EWGetsGreenIn2Steps for 10
```

This says: it is always the case that if NS has green, then two steps later EW has green. The `after after` construct chains two time steps. This works because the cycle goes (NS:Green, EW:Red) → (NS:Yellow, EW:Red) → (NS:Red, EW:Green). Alloy 6's `always` operator checks this over all time steps automatically, with no need for guards about trace length.

**Type:** Reachability property — guarantees EW traffic gets its turn.

### Property 4 (FALSE) — NS green leads directly to EW green

```alloy
assert NSGreenDirectlyToEWGreen {
  always (Intersection.ns = Green => after Intersection.ew = Green)
}
check NSGreenDirectlyToEWGreen for 10
```

This is **intentionally false**. It claims that the moment NS has green, the very next step gives EW green — skipping the yellow phase. I included this to show how Alloy generates counterexamples when a property is violated.

**Type:** False property — used to demonstrate counterexample generation.

---

## 7. Expected Results and Counterexamples

When running the four `check` commands in the Alloy Analyzer, the expected outcomes are:

| Property | Expected result |
|:---|:---|
| `NeverBothGreen` | **No counterexample.** The transitions never allow both ns=Green and ew=Green. |
| `NSGreenFollowedByNSYellow` | **No counterexample.** The transition from (Green,Red) always goes to (Yellow,Red). |
| `EWGetsGreenIn2Steps` | **No counterexample.** (Green,Red) → (Yellow,Red) → (Red,Green) always holds. |
| `NSGreenDirectlyToEWGreen` | **Counterexample found.** |

### The counterexample for Property 4

When Alloy checks `NSGreenDirectlyToEWGreen`, it finds a violation and shows a trace like:

```
State 0:  ns = Green,  ew = Red
State 1:  ns = Yellow, ew = Red     ← Expected ew=Green, but got ew=Red
```

The counterexample is just two steps. Alloy shows that when NS is green, the next step gives NS yellow and keeps EW red — it does not jump to EW green. The assertion claimed `s.next.ew = Green`, but the actual next state has `ew = Red`. This directly contradicts the property, so the check fails.

This is the kind of feedback that makes model checking useful. The tool automatically finds the shortest execution that breaks the property and presents it as a concrete trace.

### Why the bounded check is sufficient

The `for exactly 8 Step` scope creates 8 Step atoms — two full cycles of the controller. Since the full cycle is only 4 steps, any property violation would show up within the first cycle. For this system, 8 steps is more than enough.

---

## 8. Comparison Between the DFA and the Alloy Model

The DFA and the Alloy model represent the same system, but from different perspectives.

In the DFA, each state is a pair (NS color, EW color) connected by edges. We can visually trace paths through the diagram to reason about properties — for example, we can see that no state has both lights as Green by inspecting the four nodes.

In the Alloy model, we describe the same system declaratively. Each Step stores both light colors as separate fields (`ns` and `ew`), and the `fact Transitions` encodes the transition function using implications. Properties are written as assertions and verified automatically.

| Concept | DFA | Alloy |
|:---|:---|:---|
| States | Q = {(G,R), (Y,R), (R,G), (R,Y)} | `sig Step { ns: one Color, ew: one Color }` |
| Time / sequence | Implicit (follow edges) | `open util/ordering[Step]` — explicit linear chain |
| Start state | q₀ = (Green, Red) | `first.ns = Green` and `first.ew = Red` |
| Transition function | δ: Q → Q (table or diagram) | `fact Transitions { all s: Step - last \| ... }` |
| Determinism | One successor per state | Each implication uniquely determines next (ns, ew) |
| Property checking | Manual graph inspection | `assert` + `check` with automated search |

The main advantage of the Alloy approach is automation. With the DFA, I can inspect the four nodes and convince myself that no state has both lights green — but with Alloy, the tool checks it exhaustively across all reachable steps. This matters more as systems grow larger.

At the same time, the DFA diagram is more visual and easier to explain to someone seeing the system for the first time. Both representations confirm that the system is deterministic — in the DFA, each state has exactly one outgoing edge; in Alloy, each combination of (ns, ew) values uniquely determines the next combination.

---

## 9. Conclusion

In this project, I modeled a traffic light controller with two lights as a finite-state system and verified its properties using Alloy. The controller cycles through four states, each defined by the color of the NS light and the EW light, which makes it a straightforward DFA.

I specified four properties: two safety properties (both lights are never green at the same time, and yellow is never skipped), one reachability property (EW gets green within two steps of NS green), and one intentionally false property (NS green leads directly to EW green). The Alloy Analyzer confirmed the first three and produced a clear counterexample for the fourth.

The most useful thing I took away from this project is seeing how model checking connects to the automata theory we covered in class. The traffic light controller *is* a DFA, and the model checker walks through its state space the same way we would trace paths in a state diagram — except it does it exhaustively and automatically.

---

## References

- Jackson, D. (2012). *Software Abstractions: Logic, Language, and Analysis*. MIT Press.
- Alloy documentation and downloads: [https://alloytools.org](https://alloytools.org)
- Baier, C., & Katoen, J.-P. (2008). *Principles of Model Checking*. MIT Press.
- Sipser, M. (2012). *Introduction to the Theory of Computation*. Cengage Learning.
