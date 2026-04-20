# Traffic Light Controller - Alloy Model Checking

## Project Overview

Alloy is a declarative modeling language based on first-order logic and relational algebra. It allows users to define structures and constraints and then automatically analyze them using the Alloy Analyzer. Key features of Alloy include:

- Simple syntax for modeling structures
- Automatic generation of instances
- Ability to check assertions and find counterexamples
- Bounded analysis (within a finite scope)

Alloy is the most approachable option. TLA+ and NuSMV both have steeper learning curves; TLA+ uses its own mathematical notation that requires time to get comfortable with, and NuSMV requires thinking in terms of SMV modules and CTL/LTL from the start. Alloy's syntax reads more like a declarative programming language, which made the initial setup less complex. The Alloy Analyzer also has a visual interface that shows counterexamples as graphical traces, which helped a lot when debugging properties.

## Model Specification

The traffic light controller manages an intersection with two directions: north-south (NS) and east-west (EW). Each direction has three states: Green, Yellow, and Red. The system ensures mutual exclusion through transition rules that prevent both directions from being green simultaneously.

## Properties Verified

1. **NeverBothGreen** - No counterexample. Ensures the system never allows both directions to be green simultaneously.

2. **NSGreenFollowedByNSYellow** - No counterexample. Guarantees that whenever the north-south direction is green, it must transition to yellow next.

3. **EWGetsGreenIn2Steps** - No counterexample. Confirms that the east-west direction reaches green within exactly two transitions from the initial state.

4. **NSGreenDirectlyToEWGreen** - Counterexample found. Demonstrates that the system cannot transition directly from north-south green to east-west green without passing through intermediate yellow states, validating the safety constraint.

## Visualizations

### Figure 1: Alloy Model Code

![Alloy Model Code](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure1_model_code.png)

Shows the complete Alloy specification including the Color enum (Red, Green, Yellow), the Intersection signature with ns and ew variables, and the transition rules. The code demonstrates the temporal operators (var, always, after) and constraint definitions that define the system behavior.

### Figure 2: Alloy Analyzer Interface

![Alloy Analyzer Interface](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure2_analyzer_interface.png))

Displays the Alloy Analyzer tool interface with the model loaded, showing the left panel with type and set definitions (sig Color, sig Green, sig Intersection, etc.). This panel provides an overview of all defined signatures and relations in the model.

### Figure 3: Execution Results Summary

![Execution Results Summary](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure3_execution_results.png)

Shows the execution console output with results of all five commands: the four property checks and the run ShowTrace. Displays which properties passed (no counterexample found) and which failed (counterexample found in NSGreenDirectlyToEWGreen).

### Figure 4: State Transition Visualization

![State Transition Visualization](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure4_state_transitions.png)

Presents the visual state machine diagram with green and yellow highlighted nodes showing transitions between Green, Yellow, and Red states for both directions. The left side shows valid transition paths, while the right side highlights critical states.

### Figure 5: Counterexample Instance Details

![Counterexample Instance Details](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure5_counterexample_details.png)

Displays the detailed table view of the counterexample instance, showing the values in the violation: ordering tables, color definitions (GreenS0, RedS0, YellowS0), and the critical this/Intersection table highlighted in yellow showing the problematic state (YellowS0, RedS0).

### Figure 6: Text Output of Counterexample

![Text Output of Counterexample](https://raw.githubusercontent.com/MaferRb/ENGI9867-Project-Alloy/refs/heads/main/project10/Images/figure6_counterexample_trace.png)

Shows the text representation of the counterexample trace with all variable assignments and clauses listed. The output explains the exact sequence: NS goes from Green to Yellow while EW remains Red, revealing why the property fails.

[Click Updated Presentation](https://docs.google.com/presentation/d/1PqBi_cRYzRyWATY1zfq3Way5RcmfAxl1/edit?usp=sharing&ouid=103813443076117236926&rtpof=true&sd=true)

