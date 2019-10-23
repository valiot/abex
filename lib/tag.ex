defmodule Abex.Tag do
  @moduledoc """
  Handles gathering the .
  """
  use GenServer
  require Logger

  defstruct ip: nil,
            path: nil,
            cpu: nil

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do

    state = %__MODULE__{
      ip: Keyword.fetch!(args, :ip),
      path: Keyword.get(args, :path, "1,0"),
      cpu: Keyword.get(args, :cpu, "lgx")
    }

    {:ok, state}
  end

  def get_all_tags(pid), do: GenServer.call(pid, :get_all_tags, 15000)

  def read(pid, params), do: GenServer.call(pid, {:read, params}, 15000)

  def write(pid, params), do: GenServer.call(pid, {:write, params}, 15000)

  def terminate(reason, state) do
    Logger.error("(#{__MODULE__}) Error: #{inspect({reason, state})}.")
  end

  def handle_call(:get_all_tags, _from, %{ip: ip, path: path} = state) do
    read_all_tags_cmd =
      :code.priv_dir(:abex)
      |> to_string()
      |> Path.join("tag_list")

    response =
      MuonTrap.cmd(read_all_tags_cmd, [ip, path])
      |> assemble_response(:get_all_tags)

    {:reply, response, state}
  end

  def handle_call({:read, params}, _from, %{ip: ip, path: path, cpu: cpu} = state) do
    read_tag_cmd =
      :code.priv_dir(:abex)
      |> to_string()
      |> Path.join("rw_tag")

    cmd_args =
      "protocol=ab_eip&gateway=#{ip}&path=#{path}&cpu=#{cpu}&elem_size=#{params[:elem_size]}&elem_count=#{params[:elem_count]}&name=#{params[:name]}"

    response =
      MuonTrap.cmd(read_tag_cmd, ["-t", params[:data_type], "-p", cmd_args])
      |> assemble_response(:read)
      |> data_type_parser(params[:data_type])

    {:reply, response, state}
  end

  def handle_call({:write, params}, _from,%{ip: ip, path: path, cpu: cpu} = state) do
    write_tag_cmd =
      :code.priv_dir(:abex)
      |> to_string()
      |> Path.join("rw_tag")

    cmd_args =
        "protocol=ab_eip&gateway=#{ip}&path=#{path}&cpu=#{cpu}&elem_size=#{params[:elem_size]}&elem_count=#{params[:elem_count]}&name=#{params[:name]}"

    response =
      MuonTrap.cmd(write_tag_cmd, ["-t", params[:data_type], "-w", params[:value] , "-p", cmd_args])
      |> assemble_response(:write)

    {:reply, response, state}
  end

  defp assemble_response({reason, 1}, _task), do: {:error, reason}

  defp assemble_response({_data, 0}, :write), do: :ok

  defp assemble_response({data, 0}, :read) do
    data
    |> String.split(" ")
    |> List.delete("")
  end

  defp assemble_response({data, 0}, :get_all_tags) do
    {data, %{}}
    |> assemble_control_tags()
    |> assemble_program_tags()
  end

  defp assemble_response(reason,_task), do: {:error, reason}

  defp assemble_tag_map([], acc), do: acc
  defp assemble_tag_map([tag_info | tail], acc) do
    tag_info_list = tag_info |> String.split("; ")
    name = tag_info_list |> Enum.at(0) |> String.trim("tag_name=")
    tid = tag_info_list |> Enum.at(1) |> String.trim("tag_instance_id=")
    tt = tag_info_list |> Enum.at(2) |> String.trim("tag_type=")
    el = tag_info_list |> Enum.at(3) |> String.trim("element_length=") |> String.to_integer()
    ad = tag_info_list |> Enum.at(4) |> String.trim("array_dimensions=")

    new_tag = %{
      tag_instance_id: tid,
      tag_type: tt,
      element_length: el,
      array_dim: ad
    }

    acc = Map.put(acc, name, new_tag)
    assemble_tag_map(tail, acc)
  end

  defp assemble_program_tags({data, acc})do
    program_tags =
      data
      |> String.split("\r\n")
      |> List.delete("")
      |> assemble_program_tags(%{})
    Map.put(acc, :program_tags, program_tags)
  end

  defp assemble_program_tags([], acc), do: acc
  defp assemble_program_tags([p_tag_info | tail], acc) do
    [program_name, program_tags] = String.split(p_tag_info, "!")
    program_tags = String.split(program_tags, "\n") |> List.delete("") |> assemble_tag_map(%{})
    acc = Map.put(acc, program_name, program_tags)
    assemble_tag_map(tail, acc)
  end


  defp assemble_control_tags({data, acc})do
    [str_ctrl_tags, str_prog_data] = String.split(data, "Program tags\n")
    ctrl_tags = String.split(str_ctrl_tags, "\n") |> List.delete("") |> assemble_tag_map(%{})
    {str_prog_data, Map.put(acc, :controller_tags, ctrl_tags)}
  end

  defp data_type_parser(raw_data, _any_data_type) when is_tuple(raw_data), do: raw_data
  defp data_type_parser(raw_data, "real32"), do: Enum.map(raw_data, fn(x) -> String.to_float(x) end)
  defp data_type_parser(raw_data, _any_data_type), do: Enum.map(raw_data, fn(x) -> String.to_integer(x) end)
end
