defmodule AbexTest do
  use ExUnit.Case
  doctest Abex

  test "module exists and has documentation" do
    assert Code.ensure_loaded?(Abex)
    {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(Abex)
    assert module_doc != :none
  end
end
