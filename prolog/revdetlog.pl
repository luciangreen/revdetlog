% revdetlog: reversible Detlog. A deterministic, cut-free program is a sequence of steps on
% registers; each step here is invertible, so the whole program runs backwards, and any
% deterministic function can be embedded reversibly (Bennett): (X, Y) -> (X, Y xor F(X)).
% That is the form quantum circuits need, so this is the bridge from Detlog to pl2qc.
%
% A program is a list of steps on a list of registers, each a number 0..M-1:
%   add(I, J)  RI := RI + RJ mod M      sub(I, J)  RI := RI - RJ mod M     (I \= J)
%   cnot(I, J)  RI := RI xor RJ          (M a power of 2; I \= J)
%   swap(I, J) exchange RI and RJ       inc(I), dec(I), neg(I) (RI := -RI mod M)
:- module(revdetlog, [run/4, invert/2, valid/3, bennett/3, run_bennett/4, gate_count/2, step/4]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% run(+Program, +M, +Registers0, -Registers)
run(P, M, R0, R) :- foldl([S, A, B]>>step(S, M, A, B), P, R0, R1), R = R1.

step(add(I, J), M, R0, R) :- I \== J, nth0(J, R0, Y), update(I, R0, [X, Z]>>(Z is (X + Y) mod M), R).
step(sub(I, J), M, R0, R) :- I \== J, nth0(J, R0, Y), update(I, R0, [X, Z]>>(Z is (X - Y) mod M), R).
step(cnot(I, J), _, R0, R) :- I \== J, nth0(J, R0, Y), update(I, R0, [X, Z]>>(Z is X xor Y), R).
step(swap(I, J), _, R0, R) :- nth0(I, R0, X), nth0(J, R0, Y), set(I, R0, Y, R1), set(J, R1, X, R).
step(inc(I), M, R0, R) :- update(I, R0, [X, Z]>>(Z is (X + 1) mod M), R).
step(dec(I), M, R0, R) :- update(I, R0, [X, Z]>>(Z is (X - 1) mod M), R).
step(neg(I), M, R0, R) :- update(I, R0, [X, Z]>>(Z is (M - X) mod M), R).

update(I, R0, F, R) :- nth0(I, R0, X), call(F, X, Z), set(I, R0, Z, R).
set(I, L0, V, L) :- length(Pre, I), append(Pre, [_|Post], L0), append(Pre, [V|Post], L).

% invert(+Program, -Inverse): undo the steps in reverse order.
invert(P, Q) :- reverse(P, R), maplist(inverse_step, R, Q0), Q = Q0.
inverse_step(add(I, J), sub(I, J)).
inverse_step(sub(I, J), add(I, J)).
inverse_step(cnot(I, J), cnot(I, J)).
inverse_step(swap(I, J), swap(I, J)).
inverse_step(inc(I), dec(I)).
inverse_step(dec(I), inc(I)).
inverse_step(neg(I), neg(I)).

% valid(+Program, +Registers, +M): every step names existing, distinct registers (and cnot needs M = 2^k).
valid(P, N, M) :- maplist(valid_step(N, M), P).
valid_step(N, M, S) :- S =.. [F|Is], maplist([I]>>(integer(I), I >= 0, I < N), Is),
    ( Is = [A, B] -> ( F == swap -> true ; A \== B ) ; true ),
    ( F == cnot -> M > 0, M /\ (M - 1) =:= 0 ; true ).

% bennett(+Table, +M, -Embedding): a function given as a table X-FX on 0..M-1 (M = 2^k) becomes
% the reversible map (X, Y) -> (X, Y xor F(X)), listed as (X,Y)-(X,Y') for every pair.
bennett(Table, M, E) :- Top is M - 1,
    findall((X, Y)-(X, Z), ( between(0, Top, X), member(X-FX, Table), between(0, Top, Y), Z is Y xor FX ), E0), E = E0.

% run_bennett(+Table, +X, +Y, -Out): one input pair through the embedding.
run_bennett(Table, X, Y, Out) :- memberchk(X-FX, Table), Z is Y xor FX, Out = (X, Z).

% gate_count(+Program, -Counts): how many of each kind of step (the circuit's size).
gate_count(P, Counts) :- maplist([S, F]>>functor(S, F, _), P, Fs), msort(Fs, Sorted), clumped_pairs(Sorted, C), Counts = C.
clumped_pairs([], []).
clumped_pairs([F|Fs], [F-N|Rest]) :- take_same(F, Fs, 1, N, Others), clumped_pairs(Others, Rest).
take_same(F, [G|Gs], N0, N, Rest) :- F == G, !, N1 is N0 + 1, take_same(F, Gs, N1, N, Rest).
take_same(_, Rest, N, N, Rest).
