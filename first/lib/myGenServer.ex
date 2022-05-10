defmodule My.Gen.Server do
  use GenServer

  defp add_to_file(new_acount) do
    file = File.read!("lib/bank_files/acounts.json")
    |> Poison.decode!()
    |> Map.put( new_acount["accountNumber"], new_acount)
    |> Poison.encode!()
    File.write!("lib/bank_files/acounts.json", file)
  end

  defp edit_file(new_data) do
    file = File.read!("lib/bank_files/acounts.json")
    |> Poison.decode!()
    |> Map.replace(new_data["accountNumber"], new_data)
    |> Poison.encode!()
    File.write!("lib/bank_files/acounts.json", file)
  end

  def start_link(data \\ []) do
    GenServer.start_link(__MODULE__, data, [])
  end

  def create_acount(firstName, lastName, server) do
    random_number =
      Enum.map(1..13, fn n ->
        :rand.uniform(9)
      end)
      |> Enum.join("")
    IO.inspect(server)
    GenServer.cast(
      server,
      {:create,
       %{
         "firstName" => firstName,
         "lastName" => lastName,
         "accountNumber" => random_number,
         "money" => 0
       }}
    )
  end

  def add_money(server, key, amount) do
    GenServer.cast(server, {:addMoney, key, amount})
  end

  def remove_money(server, key, amount) do
    GenServer.cast(server, {:takeMoney, key, amount})
  end

  def get_acount_infos(server, key) do
    GenServer.call(server, {:infos, key})
  end

  @impl true
  def init(stack) do
    table = :ets.new(:bank, [:named_table, {:read_concurrency, true}])

    File.read!("lib/bank_files/acounts.json")
    |> Poison.decode!()
    |> Enum.map(fn {key, value} ->
      :ets.insert(table, {key, value})
    end)

    {:ok, table}
  end

  @impl true
  def handle_cast({:create, newAcount}, table) do
    :ets.insert(table, {newAcount["accountNumber"], newAcount})
    add_to_file(newAcount)
    IO.inspect("ici")
    {:noreply, table}
  end

  @impl true
  def handle_cast({:addMoney, key, amount}, table) do
    [acount | _] = :ets.lookup(table, key)
    acount_infos = elem(acount, 1)
    newAcount = Map.replace(acount_infos, "money", acount_infos["money"] + amount)
    :ets.insert(table, {key, newAcount})
    edit_file(newAcount)
    {:noreply, table}
  end

  def handle_cast({:takeMoney, key, amount}, table) do
    [acount | _] = :ets.lookup(table, key)
    acount_infos = elem(acount, 1)
    newAcount = Map.replace(acount_infos, "money", acount_infos["money"] - amount)
    :ets.insert(table, {key, newAcount})
    edit_file(newAcount)
    {:noreply, table}
  end

  @impl true
  def handle_call({:infos, key}, _from, table) do
    infos = :ets.lookup(table, key)
    {:reply, infos, table}
  end
end
