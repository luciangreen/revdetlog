% Theorems about revdetlog, each proved by exhaustion over a finite domain that covers every
% kind of step. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module('../prolog/revdetlog').
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).

main :- prove_all(theorems).

steps2(S) :- member(S, [add(0,1), add(1,0), sub(0,1), sub(1,0), cnot(0,1), cnot(1,0), swap(0,1), inc(0), inc(1), dec(0), dec(1), neg(0), neg(1)]).
program(P) :- between(0, 2, L), length(P, L), maplist(steps2, P).
regs(M, [A, B]) :- Top is M - 1, between(0, Top, A), between(0, Top, B).

% 1. Every program runs backwards: its inverse undoes it, on every state.
theorem(inverse_undoes) :-
    forall(( member(M, [2, 4]), program(P), regs(M, R) ),
           ( invert(P, Q), run(P, M, R, R1), run(Q, M, R1, R2), R2 == R )).

% 2. ... and the other way round: running the inverse first, then the program, also gives back the state.
theorem(program_undoes_inverse) :-
    forall(( member(M, [2, 4]), program(P), regs(M, R) ),
           ( invert(P, Q), run(Q, M, R, R1), run(P, M, R1, R2), R2 == R )).

% 3. So every program is a bijection on the states: no two states go to the same state.
theorem(programs_are_bijections) :-
    forall(( member(M, [2, 4]), program(P) ),
           ( findall(R1, ( regs(M, R), run(P, M, R, R1) ), Outs), msort(Outs, S), sort(Outs, S) )).

% 4. Inverting twice gives the program back.
theorem(double_inverse) :- forall(program(P), ( invert(P, Q), invert(Q, P2), P2 == P )).

% 5. Bennett's embedding of any function on 0..3 is reversible (a bijection on pairs),
%    keeps X, and with Y = 0 computes F(X) with no garbage.
fn(M, T) :- Top is M - 1, numlist(0, Top, Xs), maplist([X, X-F]>>between(0, Top, F), Xs, T).
theorem(bennett_is_reversible_and_clean) :-
    forall(( member(M, [2, 4]), fn(M, T) ),
           ( bennett(T, M, E), pairs_values(E, Outs), msort(Outs, S), sort(Outs, S), length(E, L), L =:= M * M,
             forall(member((X, _)-(X2, _), E), X2 == X),
             forall(member(X-F, T), run_bennett(T, X, 0, (X, F))) )).

% 6. Running the embedding twice gives the input back (it is its own inverse).
theorem(bennett_is_an_involution) :-
    forall(( member(M, [2, 4]), fn(M, T), member(X-_, T), Top is M - 1, between(0, Top, Y) ),
           ( run_bennett(T, X, Y, (X, Z)), run_bennett(T, X, Z, (X, Y2)), Y2 == Y )).

% 7. gate_count counts every step exactly once.
theorem(gate_count_counts_every_step) :-
    forall(program(P), ( gate_count(P, C), pairs_values(C, Ns), sum_list(Ns, N), length(P, N) )).

% 8. run is steadfast: asked whether a program gives a state, it agrees with computing it.
theorem(run_is_steadfast) :-
    forall(( program(P), regs(4, R), regs(4, Guess) ), iff(run(P, 4, R, Guess), ( run(P, 4, R, Out), Out == Guess ))).
