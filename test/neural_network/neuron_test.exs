defmodule NeuralNetwork.NeuronTest do
  use ExUnit.Case

  alias NeuralNetwork.Neuron
  alias NeuralNetwork.Connection
  alias NeuralNetwork.Sigmoid

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

    GenServer.call(source_pid, {:connect_to, dest_pid})
    GenServer.call(source_pid, {:set_output, 1})
    GenServer.call(source_pid, :prop_forward)

    dest_state = GenServer.call(dest_pid, :get_state)
    in_conn = dest_state.in_conn
    expected_in_conn = %{source_pid => %Connection{value: 1}}

    assert in_conn == expected_in_conn
  end

  test "update_forward_err_deriv" do
    state = %Neuron{forward_err_derivs: %{123 => 0.6}}
    new_state = state
    |> Neuron.update_forward_err_deriv(123, 0.7)
    |> Neuron.update_forward_err_deriv(456, 1)

    expected = %{123 => 0.7, 456 => 1}
    actual = new_state.forward_err_derivs

    assert actual == expected
  end

  test "reset_weights" do
    state = %Neuron{in_conn: %{
      1 => %Connection{value: 0.7, weight: 0},
      2 => %Connection{value: 0.5, weight: 0}}}

    new_state = Neuron.reset_weights(state)

    expected_in_conn = %{
      1 => %Connection{value: 0.7, weight: 0.5},
      2 => %Connection{value: 0.5, weight: 0.5}}

    assert new_state.in_conn == expected_in_conn
  end

  test "prop_backward" do
    source_pid = Neuron.create
    dest_pid = Neuron.create

    GenServer.call(source_pid, {:connect_to, dest_pid})
    GenServer.call(source_pid, {:set_output, 1})
    GenServer.call(source_pid, :prop_forward)
    GenServer.call(dest_pid, :reset_weights)
    GenServer.call(dest_pid, :update_output)

    GenServer.call(dest_pid, {:prop_backward, 0.8})

    source_state = GenServer.call(source_pid, :get_state)

    assert length(Map.values(source_state.forward_err_derivs)) == 1
  end

  test "adjust_weights" do
    source_pid = Neuron.create
    dest_pid = Neuron.create

    GenServer.call(source_pid, {:connect_to, dest_pid})
    GenServer.call(source_pid, {:set_output, 1})
    GenServer.call(source_pid, :prop_forward)
    GenServer.call(dest_pid, :reset_weights)
    GenServer.call(dest_pid, :update_output)

    GenServer.call(dest_pid, {:prop_backward, 0.8})
    GenServer.call(source_pid, {:adjust_weights, 0.8})
    GenServer.call(dest_pid, {:adjust_weights, 0.8})

    # source_state = GenServer.call(source_pid, :get_state)
    # dest_state = GenServer.call(dest_pid, :get_state)
    # TODO: Implement assertions
  end
end
