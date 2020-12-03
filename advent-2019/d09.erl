-module(d09).
-export([main/0, exec/2]).

readlines(File) ->
    {ok, Data} = file:read_file(File),
    Bin = binary:split(Data, [<<"\n">>, <<",">>], [global, trim]),
    [binary_to_integer(X) || X <- Bin].

nth(I, L) -> lists:nth(I+1, L).
replace(L, I, V) -> lists:sublist(L, I) ++ [V] ++ lists:nthtail(I+1, L).

perms([]) -> [[]];
perms(L) -> [[H|T] || H <- L, T <- perms(L--[H])].

param(I, X, RB, L) ->
    case nth(I, L) div round(math:pow(10, X+1)) rem 10 of
        2 -> nth(nth(I+X+RB, L), L);  % relative
        1 -> nth(I+X, L);  % immediate
        0 -> nth(nth(I+X, L), L)  % position
    end.

exec(L, Output) -> exec(L, 0, 0, Output).
exec(L, I, RB, Output) ->
    case nth(I, L) rem 100 of
        1 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            Val = LVal + RVal,
            exec(replace(L, nth(I+3, L), Val), I+4, RB, Output);
        2 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            Val = LVal * RVal,
            exec(replace(L, nth(I+3, L), Val), I+4, RB, Output);
        3 ->
            receive Val -> ok end,
            exec(replace(L, nth(I+1, L), Val), I+2, RB, Output);
        4 ->
            Val = param(I, 1, RB, L),
            Output ! Val,
            exec(L, I+2, RB, Output);
        5 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            IP = if LVal /= 0 -> RVal; true -> I+3 end,
            exec(L, IP, RB, Output);
        6 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            IP = if LVal == 0 -> RVal; true -> I+3 end,
            exec(L, IP, RB, Output);
        7 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            Val = if LVal < RVal -> 1; true -> 0 end,
            exec(replace(L, nth(I+3, L), Val), I+4, RB, Output);
        8 ->
            LVal = param(I, 1, RB, L),
            RVal = param(I, 2, RB, L),
            Val = if LVal == RVal -> 1; true -> 0 end,
            exec(replace(L, nth(I+3, L), Val), I+4, RB, Output);
        9 ->
            Val = param(I, 1, RB, L),
            exec(L, I+2, RB + Val, Output);
        99 -> 0;
        _Else -> error(io_lib:format("invalid opcode: ~w", [nth(I,L)]))
    end.

loop(PID) ->
    receive
        Data ->
            case is_process_alive(PID) of
                true -> PID ! Data, loop(PID);
                false -> Data
            end
    end.
run(L, [In0, In1, In2, In3, In4]) ->
    PID4 = spawn(d07, exec, [L, self()]),
    PID4 ! In4,
    PID3 = spawn(d07, exec, [L, PID4]),
    PID3 ! In3,
    PID2 = spawn(d07, exec, [L, PID3]),
    PID2 ! In2,
    PID1 = spawn(d07, exec, [L, PID2]),
    PID1 ! In1,
    PID0 = spawn(d07, exec, [L, PID1]),
    PID0 ! In0,

    self() ! 0,
    loop(PID0).

part1(L) -> lists:max([run(L, Ins) || Ins <- perms(lists:seq(0, 4))]).
part2(L) -> lists:max([run(L, Ins) || Ins <- perms(lists:seq(5, 9))]).

main() ->
    L = readlines("in09"),
    io:fwrite("~w\n~w\n", [part1(L), part2(L)]).
