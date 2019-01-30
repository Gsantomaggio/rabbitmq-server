## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2017 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Ctl.Commands.ListConsumersCommand do
  alias RabbitMQ.CLI.Core.Helpers
  alias RabbitMQ.CLI.Ctl.{InfoKeys, RpcStream}

  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput

  def formatter(), do: RabbitMQ.CLI.Formatters.Table

  def scopes(), do: [:ctl, :diagnostics]
  def switches(), do: [timeout: :integer]
  def aliases(), do: [t: :timeout]

  @info_keys ~w(queue_name channel_pid consumer_tag
                ack_required prefetch_count arguments)a

  def info_keys(), do: @info_keys

  def merge_defaults([], opts) do
    {Enum.map(@info_keys, &Atom.to_string/1), Map.merge(%{vhost: "/", table_headers: true}, opts)}
  end

  def merge_defaults(args, opts) do
    {args, Map.merge(%{vhost: "/", table_headers: true}, opts)}
  end

  def validate(args, _) do
    case InfoKeys.validate_info_keys(args, @info_keys) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  use RabbitMQ.CLI.Core.RequiresRabbitAppRunning

  def run([_ | _] = args, %{node: node_name, timeout: timeout, vhost: vhost}) do
    info_keys = InfoKeys.prepare_info_keys(args)

    Helpers.with_nodes_in_cluster(node_name, fn nodes ->
      RpcStream.receive_list_items(
        node_name,
        :rabbit_amqqueue,
        :emit_consumers_all,
        [nodes, vhost],
        timeout,
        info_keys,
        Kernel.length(nodes)
      )
    end)
  end

  def usage() do
    "list_consumers [-p vhost] [--no-table-headers] [<consumerinfoitem> ...]"
  end

  def usage_additional() do
    "<consumerinfoitem> must be a member of the list [" <> Enum.join(@info_keys, ", ") <> "]."
  end

  def banner(_, %{vhost: vhost}), do: "Listing consumers on vhost #{vhost} ..."
end
