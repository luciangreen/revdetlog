% The predicates whose 200 inputs and outputs are recorded in io/ios.pl and io/ios.txt.
:- module(cases, [title/1, case/3]).
:- use_module('../prolog/revdetlog').
:- use_module(engine).

title('revdetlog').

step_g(N, S) :- N1 is N - 1, rnd_int(0, N1, I), rnd_int(0, N1, J0), ( J0 =:= I -> J is (I + 1) mod N ; J = J0 ),
    rnd_pick([add(I, J), sub(I, J), xor(I, J), swap(I, J), inc(I), dec(I), neg(I)], S).
prog_g(N, P) :- rnd_int(0, 5, L), length(P, L), maplist(step_g(N), P).
regs_g(N, M, R) :- length(R, N), Top is M - 1, maplist([X]>>rnd_int(0, Top, X), R).
table_g(M, T) :- Top is M - 1, numlist(0, Top, Xs), maplist([X, X-F]>>rnd_int(0, Top, F), Xs, T).

case(run, [P, M, R], run) :- rnd_int(2, 3, N), rnd_pick([2, 4, 8], M), prog_g(N, P), regs_g(N, M, R).
case(invert, [P], invert) :- prog_g(3, P).
case(round_trip, [P, M, R], round_trip) :- rnd_pick([4, 8], M), prog_g(3, P), regs_g(3, M, R).
case(bennett, [T, M], bennett) :- M = 2, table_g(M, T).
case(run_bennett, [T, X, Y], run_bennett) :- table_g(8, T), rnd_int(0, 7, X), rnd_int(0, 7, Y).
case(gate_count, [P], gate_count) :- prog_g(3, P).
case(valid, [P, N, M], valid_answer) :- prog_g(3, P), rnd_int(2, 3, N), rnd_pick([4, 6], M).

% run forwards, then the inverse: gives back the registers
round_trip(P, M, R, (R1, R2)) :- run(P, M, R, R1), invert(P, Q), run(Q, M, R1, R2).
valid_answer(P, N, M, V) :- ( valid(P, N, M) -> V = true ; V = false ).
