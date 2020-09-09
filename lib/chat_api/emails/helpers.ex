# Most of this is just copied from:
# https://github.com/jshmrtn/email_checker/blob/master/lib/email_checker/tools.ex

defmodule ChatApi.Emails.Helpers do
  @moduledoc false

  @email_regex ~r/^(?<user>[^\s]+)@(?<domain>[^\s]+\.[^\s]+)$/

  def extract_domain_name(email) do
    case Regex.named_captures(email_regex(), email) do
      %{"domain" => domain} ->
        domain

      _ ->
        nil
    end
  end

  def email_regex do
    @email_regex
  end

  def lookup(nil), do: nil

  def lookup(domain_name) do
    domain_name
    |> lookup_all_mx_records()
    |> take_lowest_mx_record()
  end

  def valid_format?(email) do
    email =~ @email_regex
  end

  def valid_mx?(email) do
    email
    |> extract_domain_name()
    |> lookup()
    |> present?()
  end

  def valid?(email) do
    valid_format?(email) && valid_mx?(email)
  end

  defp lookup_all_mx_records(domain_name) do
    domain_name
    |> String.to_charlist()
    |> :inet_res.lookup(:in, :mx, [], max_timeout())
    |> normalize_mx_records_to_string()
  end

  defp normalize_mx_records_to_string(nil), do: []

  defp normalize_mx_records_to_string(domains) do
    normalize_mx_records_to_string(domains, [])
  end

  defp normalize_mx_records_to_string([], normalized_domains) do
    normalized_domains
  end

  defp normalize_mx_records_to_string([{priority, domain} | domains], normalized_domains) do
    normalize_mx_records_to_string(domains, [{priority, to_string(domain)} | normalized_domains])
  end

  defp sort_mx_records_by_priority(nil), do: []

  defp sort_mx_records_by_priority(domains) do
    Enum.sort(domains, fn {priority, _domain}, {other_priority, _other_domain} ->
      priority < other_priority
    end)
  end

  defp take_lowest_mx_record(mx_records) do
    mx_records
    |> sort_mx_records_by_priority()
    |> case do
      [{_lower_priority, domain} | _rest] ->
        domain

      _ ->
        nil
    end
  end

  defp max_timeout do
    # TODO: use env setting
    10_000
  end

  defp present?(nil), do: false

  defp present?(string), do: String.length(string) > 0
end
