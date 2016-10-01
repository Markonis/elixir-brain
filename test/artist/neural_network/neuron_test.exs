defmodule Artist.NeuralNetwork.NeuronTest do
  use ExUnit.Case

  alias Artist.NeuralNetwork.Neuron
  alias Artist.NeuralNetwork.Connection
  alias Artist.NeuralNetwork.Sigmoid

  doctest Neuron

  test "connect_to" do
    state = %Neuron{}

    new_state = Neuron.connect_to(state, 123)

    expected_state = %Neuron{out_conn: [123]}
    assert new_state == expected_state
  end

  test "update_input_conn" do
    state = %Neuron{in_conn: %{123 => %Connection{}}}

    new_state = Neuron.update_input_conn(state, 123, 1)
    new_in_conn = new_state.in_conn

    expected_in_conn = %{123 => %Connection{value: 1}}

    assert new_in_conn == expected_in_conn
  end

  test "input_sum" do
    state = %Neuron{output: 0, in_conn: %{
      1 => %Connection{value: 0.7, weight: 0.3},
      2 => %Connection{value: 0.5, weight: 0.7}}}

    input_sum = Neuron.input_sum(state)

    assert input_sum == 0.7 * 0.3 + 0.5 * 0.7
  end

  test "update_output" do
    state = %Neuron{output: 0, in_conn: %{
      1 => %Connection{value: 0.7, weight: 0.3},
      2 => %Connection{value: 0.5, weight: 0.7}}}

    new_state = Neuron.update_output(state)
    new_output = new_state.output
    expected_output = Sigmoid.value(0.7 * 0.3 + 0.5 * 0.7)

    assert new_output == expected_output
  end

  test "prop_forward" do
    source_pid = Neuron.create
    dest_pid = Neuron.create

    GenServer.cast(source_pid, {:connect_to, dest_pid})
    GenServer.cast(source_pid, {:set_output, 1})
    GenServer.cast(source_pid, :prop_forward)

    :timer.sleep(10) # Allow for the casts to be processed

    dest_state = GenServer.call(dest_pid, :get_state)
    in_conn = dest_state.in_conn
    expected_in_conn = %{source_pid => %Connection{value: 1}}

    assert in_conn == expected_in_conn
  end
end