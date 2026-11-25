# revdetlog

**Reversible Detlog.** A deterministic, cut-free program has no choicepoints, so it can be made to run backwards. revdetlog writes such programs as steps on registers, each of which can be undone. Any deterministic function can also be embedded reversibly with Bennett's trick, (X, Y) → (X, Y xor F(X)). Quantum circuits have to be reversible, so this is the form that [pl2qc](https://github.com/luciangreen/pl2qc) needs. It links [detlog2](https://github.com/luciangreen/detlog2) to the quantum repos.

## Use

```prolog
?- use_module(prolog/revdetlog).
?- run([add(0,1), swap(0,1), inc(1)], 8, [3,4], R).              % R = [4,0]
?- invert([add(0,1), swap(0,1), inc(1)], Q).                     % Q = [dec(1),swap(0,1),sub(0,1)]
?- bennett([0-1,1-0], 2, E).                                     % the reversible form of "not"
?- run_bennett([0-3,1-2,2-1,3-0], 2, 0, Out).                    % Out = (2,1): F(2) with no garbage
?- gate_count([add(0,1), add(1,0), swap(0,1)], C).               % C = [add-2, swap-1]
```

Steps are `add(I,J)`, `sub(I,J)`, `cnot(I,J)` (register I := I xor J; M must be a power of 2), `swap(I,J)`, `inc(I)`, `dec(I)` and `neg(I)`, on registers that hold 0..M−1. `bennett/3` lists the embedding as a table of pairs, not yet as a circuit of these steps.

## Proofs

`proofs/theorems.pl` proves 8 theorems by exhaustion. Each is checked on every program of up to 2 steps over 2 registers, every state, M = 2 and 4, and every function on 0..3:

1. A program's inverse undoes it.
2. The program also undoes its inverse.
3. Every program is a bijection on states.
4. Inverting twice gives the program back.
5. Bennett's embedding is a bijection that keeps X and computes F(X) with no garbage.
6. The embedding is its own inverse.
7. `gate_count` counts every step once.
8. `run` is steadfast.

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` (and `io/ios.pl`, the same as Prolog facts) records 200 inputs and outputs from real runs, with inputs made from a fixed seed. `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output (steadfastness). GitHub Actions runs the proofs and the examples on every push, and records the examples on the first one.

Licence: BSD-3-Clause.
