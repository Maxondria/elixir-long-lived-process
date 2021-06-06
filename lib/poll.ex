defmodule Poll do
  defstruct candidates: []

  def new(candidates \\ []) do
    %Poll{candidates: candidates}
  end

  # TODO: Implement functions neccesary to make the tests in
  # `test/poll_test.exs` pass. More info in README.md

  def start_link do
    spawn_link(Poll, :run, [new()])
  end

  def add_candidate(pid, name) when is_pid(pid) do
    send(pid, {:add_candidate, name})
  end

  def vote(pid, name) when is_pid(pid) do
    send(pid, {:vote, name})
  end

  def candidates(pid) when is_pid(pid) do
    send(pid, {:candidates, self()})

    receive do
      {^pid, candidates} -> candidates
    after
      5_000 -> nil
    end
  end

  def exit(pid) when is_pid(pid) do
    send(pid, :exit)
  end

  def run(%Poll{} = state) do
    receive do
      msg ->
        case handle(msg, state) do
          :exit -> :exit
          state -> run(state)
        end
    end
  end

  defp handle({:add_candidate, name}, %Poll{} = state) do
    candidate = Candidate.new(name)
    %Poll{state | candidates: [candidate | state.candidates]}
  end

  defp handle({:candidates, pid}, %Poll{} = state) do
    send(pid, {self(), state.candidates})
    state
  end

  defp handle({:vote, name}, %Poll{} = state) do
    candidates =
      state.candidates
      |> Enum.map(&maybe_vote(&1, name))
      |> IO.inspect()

    %Poll{state | candidates: candidates}
  end

  defp handle(:exit, _state), do: :exit

  defp maybe_vote(%Candidate{name: name, votes: votes} = candidate, name_to_update)
       when name_to_update == name do
    %Candidate{candidate | votes: votes + 1}
  end

  defp maybe_vote(%Candidate{} = candidate, _name_to_update), do: candidate
end
