defmodule Msgsrv.Server do
  use GenServer

  @type user_id :: integer()
  @type user :: pid() | {:user, user_id}

  @type message_id :: integer()
  @type message :: {message_id, String.t()}

  @doc """
  The API functions
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @spec join(server_pid :: pid, user :: user_id) :: :ok
  def join(server_pid, user) do
    GenServer.cast(server_pid, {:join, user})
  end

  @spec send_message(server_pid :: pid(), message) :: atom()
  def send_message(server_pid, message) do
    GenServer.cast(server_pid, {:send_message, message})
  end

  @spec get_messages(server_pid :: pid()) :: [message()]
  def get_messages(server_pid) do
    GenServer.call(server_pid, :get_messages)
  end

  @spec get_users(server_pid :: pid) :: [user()]
  def get_users(server_pid) do
    GenServer.call(server_pid, :get_users)
  end

  @doc """
  GenServer callbacks for handling users and messages
  """
  @type state :: %{users: [user()], messages: [message()]}

  @spec init([]) :: {:ok, %{messages: [], users: []}}
  def init([]) do
    {:ok, %{users: [], messages: []}} |> setup_table()
  end

  def handle_cast({:join, user}, %{users: users} = state) do
    case {length(users), Enum.member?(users, user)} do
      {10, _} ->
        IO.puts("Couldn't join as #{user} because the room is full")
        {:noreply, state}
      {_, true} ->
        IO.puts("Couldn't join as #{user} because the name is taken")
        {:noreply, state}
      _ ->
        new_users = [user | users]
        new_state = %{state | users: new_users}
        {:noreply, new_state}
    end
  end

  def handle_cast({:send_message, message}, %{messages: messages} = state) do
    :ets.insert(:msgsrv_table, {self(), message})
    new_messages = [message | messages]
    new_state = %{state | messages: new_messages}
    Enum.each(state.users, &send_user_message(&1, message))
    {:noreply, new_state}
  end

  def handle_call(:get_messages, _from, %{messages: messages} = state) do
    {:reply, messages, state}
  end

  def handle_call(:get_users, _from, %{users: users} = state) do
    {:reply, users, state}
  end

  def handle_info({:DOWN, _, :process, _, _reason}, state) do
    # Remove user from state if they crash or exit
    users = state.users |> Enum.reject(&Process.alive?/1)
    new_state = %{state | users: users}
    {:noreply, new_state}
  end

  defp setup_table(state) do
    :ets.new(:msgsrv_table, [:named_table, :set, :public])
    state
  end

  defp send_user_message(user, message) do
    send(user, {:new_message, message})
  end
end
