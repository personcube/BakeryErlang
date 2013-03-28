%% @author Matt
%% @doc @todo Add description to bakery.

-module(bakery).
-export([fib/1, start/2, server/0, manager/2, customer/0]).

fib(0) -> 0;
fib(1) -> 1;
fib(N) -> fib(N-1) + fib(N-2).

start(Num_servers, Num_customers) ->
	register(manager, spawn(bakery, manager, [[], []])),
	lists:map(fun(N) -> ServerID = spawn(bakery, server, []),
						manager ! {add_server, ServerID} end, lists:seq(1, Num_servers)),
	lists:map(fun(N) -> CustomerPid = spawn(bakery, customer, []),
						CustomerPid ! enter_bakery end, lists:seq(1, Num_customers)),
	true.

server() ->
	receive
		{serve_customer, CustomerPid} ->
			self() ! {bake_cake, CustomerPid},
			server();
		{bake_cake, CustomerPid} ->
			Num = crypto:rand_uniform(35, 40),
			io:format("Server: ~w is now making ~w cakes for customer: ~w~n", [self(), Num, CustomerPid]),
			Cake = fib(Num),
			CustomerPid ! {received_cake, Cake, self()},
			manager ! {add_server, self()},
			server()
	end.

manager(Servers, Customers) ->
	receive
		{add_server, ServerPid} ->
			if
				length(Customers) > 0 ->
					CustomerPid = lists:nth(1, Customers),
					ServerPid ! {serve_customer, CustomerPid},
					manager(Servers, lists:delete(CustomerPid, Customers));
				true ->
					manager(lists:append(Servers, [ServerPid]), Customers)
			end;		
		{add_customer, CustomerPid} ->
			if
				length(Servers) > 0 ->
					ServerPid = lists:nth(1, Servers),
					ServerPid ! {serve_customer, CustomerPid},
					manager(lists:delete(ServerPid, Servers), Customers);
				true ->
					manager(Servers, lists:append(Customers, [CustomerPid]))
			end
	end.

customer() ->
	receive
		enter_bakery -> timer:sleep(crypto:rand_uniform(100, 1000)),
						manager ! {add_customer, self()},
						customer();
		{received_cake, Cake, ServerPid} -> io:format("Customer ~w has received their cake with ~w calories from server: ~w. ~n", [self(), Cake, ServerPid]),
								 true
	end.


