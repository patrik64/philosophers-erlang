-module(philosophers).
-export([dinner/0]).

sleep(T) ->
	receive
		after T -> true
	end.

philosopherActor(Name, _, _, 0) ->
	io:format("~s is leaving.~n", [Name]),
	waiter ! guest_leaving;

philosopherActor(Name, LeftFork, RightFork, Meal) ->
	io:format("~s is thinking.~n", [Name]),
	sleep(random:uniform(300)),
	io:format("~s is hungry.~n", [Name]),
	waiter ! {forks_available, LeftFork, RightFork, self()},
	receive
		forks_given ->
			io:format("~s is eating meal nr. ~p~n", [Name, Meal]),
			sleep(random:uniform(150)),
			waiter ! {forks_released, LeftFork, RightFork},
			philosopherActor(Name, LeftFork, RightFork, Meal - 1);
		forks_busy ->
			io:format("~s's forks are busy.~n", [Name]),
			sleep(random:uniform(100)),
			philosopherActor(Name, LeftFork, RightFork, Meal)
	end.

waiterActor(_, 0) ->
	io:format("Waiter is leaving.~n"),
	diningRoom ! all_guests_left;

waiterActor(Forks, Guests) ->
	receive
		{forks_available, LeftFork, RightFork, Sender} ->
			case (lists:member(LeftFork, Forks) andalso lists:member(RightFork, Forks)) of
				true -> 
					Sender ! forks_given,
					waiterActor(Forks -- [LeftFork, RightFork], Guests);
				false -> Sender ! forks_busy
			end,
			waiterActor(Forks, Guests);
		{forks_released, LeftFork, RightFork} -> 
						waiterActor([LeftFork, RightFork | Forks], Guests);
		guest_leaving -> waiterActor(Forks, Guests - 1)
	end.

dinner() -> 	Forks = [1,2,3,4,5],
		Guests = 5,
		Meals = 5,
		io:format("Dining room opens.~n"),
		register(diningRoom, self()),
		register(waiter, spawn(fun()->waiterActor(Forks, Guests) end)),
		spawn(fun()->philosopherActor('Plato', 5, 1, Meals) end),
		spawn(fun()->philosopherActor('Descartes', 1, 2, Meals) end),
		spawn(fun()->philosopherActor('Voltaire', 2, 3, Meals) end),
		spawn(fun()->philosopherActor('Socractes', 3, 4, Meals) end),
		spawn(fun()->philosopherActor('Confucius', 4, 5, Meals) end),
		
		receive
			all_guests_left->io:format("Dining room closes.~n")
		end,
		unregister(waiter),
		unregister(diningRoom).
			