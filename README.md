# Automatic-Differentiation
Completed both forward and reverse mode automatic differentiation

## Wiki = https://en.wikipedia.org/wiki/Automatic_differentiation

Forward and reverse accumulation are just two (extreme) ways of traversing the chain rule. The problem of computing a full Jacobian of f : ℝn → ℝm with a minimum number of arithmetic operations is known as the optimal Jacobian accumulation (OJA) problem, which is NP-complete.[7] Central to this proof is the idea that algebraic dependencies may exist between the local partials that label the edges of the graph. In particular, two or more edge labels may be recognized as equal. The complexity of the problem is still open if it is assumed that all edge labels are unique and algebraically independent.

## How to run
Install stack and use "stack ghci AutoDiff.hs" to load the file into a ghc interpreter enviorment.

Call either forward or reversed functions given an empty enviorment: [] and any mathmatical expression created using the ValueHat constructor function.

Example:

stack runghci AutoDiff.hs

## input:
reversed (Map.singleton "x" (DualNumber 5 (\k -> 1))) (PlusE (RealE 5) (VarE "x"))

## Output:
Just FDualNumber 10.0 1.0
