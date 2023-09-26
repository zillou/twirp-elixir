defmodule Twirp.Protoc.Generator do
  @moduledoc false
  # What even does this code do?

  alias Twirp.Protoc.Generator.Service, as: ServiceGenerator

  def generate(ctx, desc) do
    name = new_file_name(desc.name)

    %Google.Protobuf.Compiler.CodeGeneratorResponse.File{
      name: name,
      content: generate_content(ctx, desc)
    }
  end

  defp new_file_name(name) do
    String.replace_suffix(name, ".proto", "_twirp.ex")
  end

  def generate_content(ctx, desc) do
    module_prefix = (desc.options && Map.get(desc.options, :elixir_module_prefix)) || (desc.package || "")
    ctx = %{
      ctx
      | package: desc.package || "",
        syntax: syntax(desc.syntax),
        module_prefix: module_prefix
    }

    ctx = %{ctx | dep_type_mapping: get_dep_type_mapping(ctx, desc.dependency, desc.name)}

    list = ServiceGenerator.generate_list(ctx, desc.service)

    list
    |> List.flatten()
    |> Enum.join("\n")
    |> format_code()
  end

  @doc false
  def get_dep_pkgs(%{pkg_mapping: mapping, package: pkg}, deps) do
    pkgs = deps |> Enum.map(fn dep -> mapping[dep] end)
    pkgs = if pkg && String.length(pkg) > 0, do: [pkg | pkgs], else: pkgs
    Enum.sort(pkgs, &(byte_size(&2) <= byte_size(&1)))
  end

  def get_dep_type_mapping(%{global_type_mapping: global_mapping}, deps, file_name) do
    mapping =
      Enum.reduce(deps, %{}, fn dep, acc ->
        Map.merge(acc, global_mapping[dep])
      end)

    Map.merge(mapping, global_mapping[file_name])
  end

  defp syntax("proto3"), do: :proto3
  defp syntax(_), do: :proto2

  def format_code(code) do
    formated =
      if Code.ensure_loaded?(Code) && function_exported?(Code, :format_string!, 2) do
        code
        |> Code.format_string!(locals_without_parens: [rpc: 4, package: 1, service: 1])
        |> IO.iodata_to_binary()
      else
        code
      end

    if formated == "" do
      formated
    else
      formated <> "\n"
    end
  end
end
