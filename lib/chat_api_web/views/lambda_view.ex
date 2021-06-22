defmodule ChatApiWeb.LambdaView do
  use ChatApiWeb, :view
  alias ChatApiWeb.LambdaView

  def render("index.json", %{lambdas: lambdas}) do
    %{data: render_many(lambdas, LambdaView, "lambda.json")}
  end

  def render("show.json", %{lambda: lambda}) do
    %{data: render_one(lambda, LambdaView, "lambda.json")}
  end

  def render("lambda.json", %{lambda: lambda}) do
    %{
      id: lambda.id,
      object: "lambda",
      created_at: lambda.inserted_at,
      updated_at: lambda.updated_at,
      account_id: lambda.account_id,
      name: lambda.name,
      description: lambda.description,
      code: lambda.code,
      language: lambda.language,
      runtime: lambda.runtime,
      status: lambda.status,
      last_deployed_at: lambda.last_deployed_at,
      last_executed_at: lambda.last_executed_at,
      metadata: lambda.metadata
    }
  end
end
