defmodule Dynamo::App do
  # Hook invoked when Dynamo::App is used.
  # It initializes the app data, registers a
  # compile callback and import Dynamo::DSL macros.
  defmacro __using__(module) do
    Module.merge_data module, routes: []
    Module.add_compile_callback module, __MODULE__
    quote { require Dynamo::DSL, import: true }
  end

  defmacro __compiling__(module) do
    # Compile routes
    routes = Orddict.fetch Module.read_data(module), :routes, []
    Dynamo::Router.compile(module, routes)

    # Clean up any internal state
    # TODO: Use Module.remove_data once we add it to Elixir
    Module.merge_data module, routes: []

    # Generate both an service entry points
    quote do
      def run(options // []) do
        Dynamo.run(__MODULE__, options)
      end

      def service(request, response) do
        path = request.path
        verb = request.request_method
        case recognize_route(verb, path, []) do
        match: { :ok, fun, _ }
          apply __MODULE__, fun, [request, response]
        match: :error
          IO.puts "SERVE 404"
        end
      end
    end
  end
end