defmodule ChatApi.Aws do
  @moduledoc """
  A module to handle interactions with AWS

  TODO: clean this up!
  """

  alias ChatApi.Aws.Config

  @type config() :: %{
          aws_key_id: binary(),
          aws_secret_key: binary(),
          bucket_name: binary(),
          function_bucket_name: binary(),
          region: binary()
        }

  # S3

  @spec upload(Plug.Upload.t(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file, identifier) do
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate(),
         {:ok, file_binary} <- File.read(file.path) do
      upload_binary(file_binary, identifier, bucket_name)
    else
      {:error, :invalid_aws_config, errors} -> {:error, :invalid_aws_config, errors}
      {:error, error} -> {:error, :file_error, error}
      error -> error
    end
  end

  @spec upload(binary(), binary(), binary()) :: {:error, any} | {:ok, any()}
  def upload(file_path, identifier, bucket_name) when is_binary(file_path) do
    case File.read(file_path) do
      {:ok, file_binary} -> upload_binary(file_binary, identifier, bucket_name)
      {:error, error} -> {:error, :file_error, error}
    end
  end

  @spec upload_binary(binary(), binary()) :: {:error, any()} | {:ok, any()}
  def upload_binary(file_binary, identifier) do
    # TODO: consolidate Config methods with env variables below
    with {:ok, %{bucket_name: bucket_name}} <- Config.validate() do
      upload_binary(file_binary, identifier, bucket_name)
    end
  end

  @spec upload_binary(binary(), binary(), binary()) :: {:error, any} | {:ok, any()}
  def upload_binary(file_binary, identifier, bucket_name) do
    bucket_name
    |> ExAws.S3.put_object(identifier, file_binary)
    |> ExAws.request!()
    |> case do
      %{status_code: 200} = result -> {:ok, result}
      result -> {:error, result}
    end
  end

  @spec download_file(binary(), binary(), keyword()) :: {:error, any()} | {:ok, any()}
  def download_file(identifier, bucket_name, opts \\ [])
      when is_binary(identifier) and is_binary(bucket_name) do
    bucket_name
    |> ExAws.S3.get_object(identifier)
    |> ExAws.request!(opts)
    |> case do
      %{status_code: 200} = result -> {:ok, result}
      result -> {:error, result}
    end
  end

  @spec download_file_url(URI.t() | binary(), keyword()) :: {:error, any()} | {:ok, any()}
  def download_file_url(uri, opts \\ [])

  def download_file_url(%URI{host: host, path: path}, opts)
      when is_binary(host) and is_binary(path) do
    with [bucket, "s3", "amazonaws", "com"] <- String.split(host, "."),
         [identifier] <- String.split(path, "/", trim: true) do
      download_file(identifier, bucket, opts)
    else
      _ ->
        {:error, :invalid_uri}
    end
  end

  def download_file_url(uri, opts) when is_binary(uri) do
    uri |> URI.parse() |> download_file_url(opts)
  end

  @spec get_file_url(binary(), binary()) :: binary()
  def get_file_url(identifier, bucket) do
    "https://#{bucket}.s3.amazonaws.com/#{identifier}"
  end

  @spec get_file_url(binary()) :: binary() | nil
  def get_file_url(identifier) do
    case Config.validate() do
      {:ok, %{bucket_name: bucket}} -> get_file_url(identifier, bucket)
      _ -> nil
    end
  end

  @spec generate_unique_filename(Plug.Upload.t() | binary()) :: binary()
  def generate_unique_filename(%Plug.Upload{filename: filename}),
    do: generate_unique_filename(filename)

  def generate_unique_filename(filename) do
    uuid = UUID.uuid4(:hex)
    sanitized_filename = String.replace(filename, " ", "-")

    "#{uuid}-#{sanitized_filename}"
  end

  # SES (Simple Email Service)

  @spec download_email_message(binary()) :: {:error, any()} | {:ok, any()}
  def download_email_message(ses_message_id) do
    bucket_name = Application.get_env(:chat_api, :ses_bucket_name)
    ses_region = Application.get_env(:chat_api, :ses_region)

    download_file(ses_message_id, bucket_name, region: ses_region)
  end

  @spec retrieve_formatted_email(binary()) :: {:error, any()} | {:ok, any()}
  def retrieve_formatted_email(ses_message_id) do
    with {:ok, %{body: email}} <- download_email_message(ses_message_id),
         %Mail.Message{} = parsed <- Mail.Parsers.RFC2822.parse(email) do
      {:ok, format_ses_email(ses_message_id, parsed)}
    end
  end

  # For replies, the `References` and `In-Reply-To` headers need to have the message-id
  # of the previous email, and the subject line has to match as well (with a "Re:" prefix?)
  @spec build_email_message(map()) :: binary()
  def build_email_message(
        %{
          to: to,
          from: from,
          subject: subject,
          text: text
        } = email
      ) do
    # TODO: should this ever be multipart: false (e.g. Mail.build instead of Mail.build_multipart)?
    Mail.build_multipart()
    |> Mail.put_to(to)
    |> Mail.put_from(from)
    # TODO: how should we handle reply_to addresses?
    |> Mail.put_reply_to(Map.get(email, :reply_to, from))
    |> Mail.put_cc(Map.get(email, :cc, []))
    |> Mail.put_bcc(Map.get(email, :bcc, []))
    |> Mail.put_subject(subject)
    |> Mail.put_text(text)
    # NB: this overrides the text body if multipart: false
    |> build_email_attachments(Map.get(email, :attachments, []))
    |> build_email_html(email)
    |> build_email_headers(email)
    |> IO.inspect(label: "Pre-rendered SES email")
    |> Mail.Renderers.RFC2822.render()
  end

  def build_email_html(message, %{html: nil}), do: message

  def build_email_html(message, %{html: html}) when is_binary(html),
    do: Mail.put_html(message, html)

  def build_email_html(message, _), do: message

  def build_email_headers(message, %{in_reply_to: in_reply_to, references: references}) do
    message
    |> Mail.Message.put_header("In-Reply-To", in_reply_to)
    |> Mail.Message.put_header("References", references)
  end

  def build_email_headers(message, _), do: message

  # Attachments should be structured like: [{filename, binary}]
  # See https://github.com/DockYard/elixir-mail#multi-part
  def build_email_attachments(message, [attachment | rest]) do
    message
    |> Mail.put_attachment(attachment)
    |> build_email_attachments(rest)
  end

  def build_email_attachments(message, _), do: message

  @spec send_email(map()) :: any()
  def send_email(%{to: _, from: _, subject: _, text: _} = email) do
    region = Application.get_env(:chat_api, :ses_region)

    email
    |> build_email_message()
    |> ExAws.SES.send_raw_email()
    |> ExAws.request!(%{region: region})
    |> case do
      %{body: xml, status_code: 200} = result when is_binary(xml) ->
        Map.put(result, :body, parse_send_email_response_xml(xml))

      response ->
        response
    end
  end

  @spec parse_send_email_response_xml(binary()) :: map()
  def parse_send_email_response_xml(xml) do
    %{
      message_id: SweetXml.xpath(xml, SweetXml.sigil_x("//MessageId/text()")),
      request_id: SweetXml.xpath(xml, SweetXml.sigil_x("//RequestId/text()"))
    }
  end

  @spec format_ses_email(binary(), Mail.Message.t()) :: map()
  def format_ses_email(ses_message_id, %Mail.Message{body: body, headers: headers, parts: parts})
      when not is_nil(headers) do
    %{
      id: ses_message_id,
      headers: headers,
      message_id: headers["message-id"],
      subject: headers["subject"],
      from: headers["from"],
      to: headers["to"],
      cc: headers["cc"],
      bcc: headers["bcc"],
      in_reply_to: headers["in-reply-to"],
      references: headers["references"],
      # Default to the body, may override with `format_message_parts` if multipart: true
      text: body,
      html: body,
      formatted_text: ChatApi.Google.Gmail.remove_original_email(body),
      # TODO: handle attachments
      attachments: []
    }
    |> format_message_parts(parts)
  end

  @spec format_message_parts(map(), list()) :: map()
  def format_message_parts(message, parts \\ []) do
    Enum.reduce(parts, message, fn part, acc ->
      case part do
        %Mail.Message{multipart: true, parts: embedded_parts} ->
          format_message_parts(acc, embedded_parts)

        %Mail.Message{body: text, headers: %{"content-type" => "text/plain"}} ->
          Map.merge(acc, %{
            text: text,
            formatted_text: ChatApi.Google.Gmail.remove_original_email(text)
          })

        %Mail.Message{body: html, headers: %{"content-type" => "text/html"}} ->
          Map.merge(acc, %{html: html})

        %Mail.Message{body: text, headers: %{"content-type" => ["text/plain", _]}} ->
          Map.merge(acc, %{
            text: text,
            formatted_text: ChatApi.Google.Gmail.remove_original_email(text)
          })

        %Mail.Message{body: html, headers: %{"content-type" => ["text/html", _]}} ->
          Map.merge(acc, %{html: html})

        %Mail.Message{
          body: binary,
          headers: %{
            "content-disposition" => ["attachment", {"filename", filename}],
            "content-type" => [content_type, metadata]
          }
        } ->
          Map.merge(acc, %{
            attachments: [
              %{
                body: binary,
                filename: filename,
                message_id: message.id,
                content_type: content_type,
                metadata: metadata
              }
              | acc.attachments
            ]
          })

        _ ->
          acc
      end
    end)
  end

  def format_metadata_email_field({name, email}), do: "#{name} <#{email}>"
  def format_metadata_email_field({email}), do: email
  def format_metadata_email_field(email) when is_binary(email), do: email

  def format_metadata_email_field(emails) when is_list(emails),
    do: Enum.map(emails, &format_metadata_email_field/1)

  def format_metadata_email_field(_), do: nil

  def format_message_metadata(message) do
    %{
      ses_id: message.id,
      ses_message_id: message.message_id,
      ses_subject: message.subject,
      ses_from: format_metadata_email_field(message.from),
      ses_to: format_metadata_email_field(message.to),
      ses_cc: format_metadata_email_field(message.cc),
      ses_bcc: format_metadata_email_field(message.bcc),
      ses_in_reply_to: format_metadata_email_field(message.in_reply_to),
      ses_references: message.references
    }
    |> maybe_merge_raw_html(message)
  end

  def maybe_merge_raw_html(metadata, %{formatted_text: nil, html: html}) when is_binary(html),
    do: Map.merge(metadata, %{ses_html: html})

  def maybe_merge_raw_html(metadata, _), do: metadata

  # Lambda

  @spec list_lambda_functions :: list()
  def list_lambda_functions() do
    ExAws.Lambda.list_functions() |> ExAws.request!()
  end

  # the lambda repo doesn't get maintained so it doesn't return a status code
  @spec get_lambda_function(binary()) :: any()
  def get_lambda_function(function_name) do
    function_name
    |> ExAws.Lambda.get_function()
    |> ExAws.request!()
  end

  @spec create_lambda_function(binary(), map()) :: any()
  def create_lambda_function(function_name, params \\ %{}) do
    %ExAws.Operation.JSON{
      http_method: :post,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions",
      data: %{
        "FunctionName" => function_name,
        "Handler" => Map.get(params, "handler", "index.handler"),
        "Runtime" => Map.get(params, "runtime", "nodejs14.x"),
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "Code" => %{
          "S3Bucket" => Map.get(params, "bucket", function_bucket_name()),
          "S3Key" => function_name
        },
        "Environment" => %{
          "Variables" => Map.get(params, "env", %{})
        }
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec update_lambda_function_code(binary(), map()) :: any()
  def update_lambda_function_code(function_name, params \\ %{}) do
    # Reference: https://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionCode.html
    %ExAws.Operation.JSON{
      http_method: :put,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions/#{function_name}/code",
      data: %{
        "S3Bucket" => Map.get(params, "bucket", function_bucket_name()),
        "S3Key" => function_name
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec update_lambda_function_config(binary(), map()) :: any()
  def update_lambda_function_config(function_name, params \\ %{}) do
    # Reference: https://docs.aws.amazon.com/lambda/latest/dg/API_UpdateFunctionConfiguration.html
    %ExAws.Operation.JSON{
      http_method: :put,
      headers: [{"content-type", "application/json"}],
      path: "/2015-03-31/functions/#{function_name}/configuration",
      data: %{
        "Runtime" => Map.get(params, "runtime", "nodejs14.x"),
        "Role" => "arn:aws:iam::#{aws_account_id()}:role/#{function_role()}",
        "Environment" => %{
          "Variables" => Map.get(params, "env", %{})
        }
      },
      service: :lambda
    }
    |> ExAws.request!()
  end

  @spec create_function_by_file(binary(), binary(), map()) :: any()
  def create_function_by_file(file_path, function_name, params \\ %{}) do
    bucket = function_bucket_name()

    with {:ok, _} <- upload(file_path, function_name, bucket) do
      create_lambda_function(
        function_name,
        Map.merge(params, %{
          "bucket" => bucket
        })
      )
    end
  end

  def update_function_by_file(file_path, function_name, params \\ %{}) do
    bucket = function_bucket_name()

    with {:ok, _} <- upload(file_path, function_name, bucket) do
      update_lambda_function_code(function_name, params)
    end
  end

  def create_function_by_code(code, function_name, params \\ %{}) do
    bucket = function_bucket_name()
    # TODO: does it matter what we name the zip file? (e.g. "test.zip"?)
    with {:ok, {_filename, bytes}} <- :zip.create("test.zip", [{'index.js', code}], [:memory]),
         {:ok, _} <- upload_binary(bytes, function_name, bucket) do
      create_lambda_function(
        function_name,
        Map.merge(params, %{
          "bucket" => bucket
        })
      )
    end
  end

  def update_function_by_code(code, function_name, params \\ %{}) do
    bucket = function_bucket_name()
    # TODO: does it matter what we name the zip file? (e.g. "test.zip"?)
    with {:ok, {_filename, bytes}} <- :zip.create("test.zip", [{'index.js', code}], [:memory]),
         {:ok, _} <- upload_binary(bytes, function_name, bucket) do
      # This update works because it syncs with the uploaded binary to S3 in the method above
      update_lambda_function_code(function_name, params)
    end
  end

  def update_function_configuration(function_name, params \\ %{}) do
    update_lambda_function_config(function_name, params)
  end

  @spec delete_lambda_function(binary()) :: any()
  def delete_lambda_function(function_name) do
    function_name
    |> ExAws.Lambda.delete_function()
    |> ExAws.request!()
  end

  @spec invoke_lambda_function(binary(), map()) :: any()
  def invoke_lambda_function(function_name, payload) do
    function_name
    |> ExAws.Lambda.invoke(payload, %{})
    |> ExAws.request!()
  end

  # TODO: maybe rename to `lambda` instead of just `function`?
  defp function_bucket_name(), do: Application.get_env(:chat_api, :function_bucket_name)
  defp function_role(), do: Application.get_env(:chat_api, :function_role)
  defp aws_account_id(), do: Application.get_env(:chat_api, :aws_account_id)
end
