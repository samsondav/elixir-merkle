defmodule Merkle do
  @doc """
  Return merkle tree node following route.

  e.g. 00000101 (0 being left, 1 being right)
  """
  def lookup(path, route) when is_binary(path) and is_binary(route) do
    root = root(path)

    route
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.reduce(root, fn idx, node ->
      child = Enum.at(node.children, idx)

      if is_nil(child) do
        raise "Route too deep, max depth is #{depth(root)}"
      else
        child
      end
    end)
  end

  @doc """
  Read a file, build a merkle tree and return the root.
  """
  def root(path) when is_binary(path) do
    path
    |> bottom_leaf_nodes
    |> build_tree
  end

  defp build_tree([root]), do: root

  defp build_tree(nodes) do
    child_pairs = Enum.chunk_every(nodes, 2)

    parents =
      Enum.map(child_pairs, fn child_pair ->
        case child_pair do
          [left, right] ->
            %Merkle.Node{
              value: hash(left.value <> right.value),
              children: [left, right]
            }

          [left] ->
            %Merkle.Node{
              value: hash(left.value <> left.value),
              children: [left, left]
            }
        end
      end)

    build_tree(parents)
  end

  defp bottom_leaf_nodes(path) do
    path
    |> File.stream!([], 1024)
    |> Enum.map(fn block ->
      %Merkle.Node{
        value: hash(block),
        children: []
      }
    end)
  end

  defp hash(binary) do
    :crypto.hash(:sha256, binary)
  end

  defp depth(node) do
    depth(node, 0)
  end

  defp depth(%{children: []}, depth) do
    depth
  end

  defp depth(%{children: [l, _]}, depth) do
    depth(l, depth + 1)
  end
end
