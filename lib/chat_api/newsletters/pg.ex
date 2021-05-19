defmodule ChatApi.Newsletters.Pg do
  @moduledoc """
  A module to handle parsing and sending PG essays
  """

  require Logger

  alias ChatApi.Google

  @months [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ]

  @spec get_essay_urls() :: [binary()]
  def get_essay_urls() do
    {:ok, %{body: html}} = Tesla.get("http://www.paulgraham.com/articles.html")
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find("table table a")
    |> Floki.attribute("href")
    |> Stream.uniq()
    |> Enum.map(&"http://www.paulgraham.com/#{&1}")
  end

  @spec extract_essay_data(binary()) :: {:error, binary()} | {:ok, {binary(), binary(), binary()}}
  def extract_essay_data(url \\ "http://www.paulgraham.com/useful.html") do
    Logger.debug("Fetching url: #{inspect(url)}")

    {:ok, %{body: html}} = Tesla.get(url)
    {:ok, document} = Floki.parse_document(html)

    title =
      document
      |> Floki.find("table table img")
      |> Floki.attribute("alt")
      |> List.first()

    document
    |> Floki.find("table table font")
    |> Stream.map(fn {_tag, _attrs, nodes} -> nodes end)
    |> Enum.find(fn nodes ->
      nodes |> Floki.text() |> String.contains?(@months)
    end)
    |> case do
      nil ->
        {:error, "Unrecognized essay format"}

      content ->
        text = Floki.text(content)

        html = """
        <div style=\"max-width:480px\">
          #{Floki.raw_html(content)}
          <br />
          <br />
          <p>(Read online at #{url})</p>
        </div>
        """

        {:ok, {title, text, html}}
    end
  end

  def notify(token, url, recipients) when is_list(recipients) do
    with %{"emailAddress" => sender} <- Google.Gmail.get_profile(token) do
      case extract_essay_data(url) do
        {:ok, {title, text, html}} ->
          Logger.debug("Sending PG essay #{inspect(url)} to #{inspect(recipients)}")

          Google.Gmail.send_message(token, %{
            to: sender,
            from: {"PG Essay Newsletter", sender},
            # NB: just sending to all as bcc for now
            bcc: recipients,
            subject: "PG Essay: #{title}",
            text: text,
            html: html
          })

        {:error, reason} ->
          Logger.error("Could not send PG essay newsletter email: #{inspect(reason)}")

          nil
      end
    end
  end

  def notify(token, url, recipient), do: notify(token, url, [recipient])

  def run!() do
    with {:ok, %{account_id: account_id, sheet_id: sheet_id, start_date: start_date}} <-
           get_config(),
         %{refresh_token: sheets_token} <-
           Google.get_authorization_by_account(account_id, %{client: "sheets"}),
         %{refresh_token: gmail_token} <-
           Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}) do
      url = pick_essay_url(Date.utc_today(), start_date)

      recipients =
        sheets_token
        |> Google.Sheets.get_spreadsheet_by_id!(sheet_id)
        |> Google.Sheets.format_as_json()
        |> Enum.map(fn record ->
          case record do
            %{"email" => email, "name" => name} when is_nil(name) or name == "" -> email
            %{"email" => email, "name" => name} -> {name, email}
            %{"email" => email} -> email
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      notify(gmail_token, url, recipients)
    end
  end

  @spec pick_essay_url(Date.t(), Date.t()) :: binary()
  def pick_essay_url(current_date, start_date) do
    index = current_date |> Date.diff(start_date) |> max(0)

    top_ranked_urls() |> Enum.at(index)
  end

  @default_start_date ~D[2021-02-17]

  def config() do
    %{
      account_id: System.get_env("REACT_APP_ADMIN_ACCOUNT_ID"),
      sheet_id: System.get_env("PG_NEWSLETTER_SHEET_ID"),
      start_date:
        case Date.from_iso8601(System.get_env("PG_NEWSLETTER_START_DATE", "")) do
          {:ok, date} -> date
          _ -> @default_start_date
        end
    }
  end

  def get_config() do
    case config() do
      %{account_id: account_id} when is_nil(account_id) or account_id == "" ->
        {:error, "Please set the REACT_APP_ADMIN_ACCOUNT_ID environment variable"}

      %{sheet_id: sheet_id} when is_nil(sheet_id) or sheet_id == "" ->
        {:error, "Please set the PG_NEWSLETTER_SHEET_ID environment variable"}

      config ->
        {:ok, config}
    end
  end

  @spec top_ranked_urls() :: [binary()]
  def top_ranked_urls() do
    # From http://www.solipsys.co.uk/new/PaulGrahamEssaysRanking.html
    [
      "http://www.paulgraham.com/avg.html",
      "http://www.paulgraham.com/say.html",
      "http://www.paulgraham.com/icad.html",
      "http://www.paulgraham.com/essay.html",
      "http://www.paulgraham.com/diff.html",
      "http://www.paulgraham.com/nerds.html",
      "http://www.paulgraham.com/taste.html",
      "http://www.paulgraham.com/gh.html",
      "http://www.paulgraham.com/road.html",
      "http://www.paulgraham.com/wealth.html",
      "http://www.paulgraham.com/power.html",
      "http://www.paulgraham.com/venturecapital.html",
      "http://www.paulgraham.com/gba.html",
      "http://www.paulgraham.com/start.html",
      "http://www.paulgraham.com/hiring.html",
      "http://www.paulgraham.com/america.html",
      "http://www.paulgraham.com/progbot.html",
      "http://www.paulgraham.com/inequality.html",
      "http://www.paulgraham.com/siliconvalley.html",
      "http://www.paulgraham.com/ladder.html",
      "http://www.paulgraham.com/love.html",
      "http://www.paulgraham.com/procrastination.html",
      "http://www.paulgraham.com/credentials.html",
      "http://www.paulgraham.com/equity.html",
      "http://www.paulgraham.com/die.html",
      "http://www.paulgraham.com/hs.html",
      "http://www.paulgraham.com/spam.html",
      "http://www.paulgraham.com/angelinvesting.html",
      "http://www.paulgraham.com/badeconomy.html",
      "http://www.paulgraham.com/highres.html",
      "http://www.paulgraham.com/pypar.html",
      "http://www.paulgraham.com/ideas.html",
      "http://www.paulgraham.com/better.html",
      "http://www.paulgraham.com/ffb.html",
      "http://www.paulgraham.com/relres.html",
      "http://www.paulgraham.com/webstartups.html",
      "http://www.paulgraham.com/hundred.html",
      "http://www.paulgraham.com/bronze.html",
      "http://www.paulgraham.com/submarine.html",
      "http://www.paulgraham.com/marginal.html",
      "http://www.paulgraham.com/startupfunding.html",
      "http://www.paulgraham.com/convergence.html",
      "http://www.paulgraham.com/hiresfund.html",
      "http://www.paulgraham.com/popular.html",
      "http://www.paulgraham.com/stuff.html",
      "http://www.paulgraham.com/trolls.html",
      "http://www.paulgraham.com/googles.html",
      "http://www.paulgraham.com/startupmistakes.html",
      "http://www.paulgraham.com/top.html",
      "http://www.paulgraham.com/hp.html",
      "http://www.paulgraham.com/bubble.html",
      "http://www.paulgraham.com/langdes.html",
      "http://www.paulgraham.com/vcsqueeze.html",
      "http://www.paulgraham.com/cities.html",
      "http://www.paulgraham.com/13sentences.html",
      "http://www.paulgraham.com/fundraising.html",
      "http://www.paulgraham.com/guidetoinvestors.html",
      "http://www.paulgraham.com/desres.html",
      "http://www.paulgraham.com/judgement.html",
      "http://www.paulgraham.com/unions.html",
      "http://www.paulgraham.com/maybe.html",
      "http://www.paulgraham.com/startuphubs.html",
      "http://www.paulgraham.com/control.html",
      "http://www.paulgraham.com/notnot.html",
      "http://www.paulgraham.com/opensource.html",
      "http://www.paulgraham.com/5founders.html",
      "http://www.paulgraham.com/6631327.html",
      "http://www.paulgraham.com/addiction.html",
      "http://www.paulgraham.com/airbnb.html",
      "http://www.paulgraham.com/ambitious.html",
      "http://www.paulgraham.com/apple.html",
      "http://www.paulgraham.com/artistsship.html",
      "http://www.paulgraham.com/boss.html",
      "http://www.paulgraham.com/charisma.html",
      "http://www.paulgraham.com/college.html",
      "http://www.paulgraham.com/colleges.html",
      "http://www.paulgraham.com/copy.html",
      "http://www.paulgraham.com/determination.html",
      "http://www.paulgraham.com/disagree.html",
      "http://www.paulgraham.com/discover.html",
      "http://www.paulgraham.com/distraction.html",
      "http://www.paulgraham.com/divergence.html",
      "http://www.paulgraham.com/fix.html",
      "http://www.paulgraham.com/founders.html",
      "http://www.paulgraham.com/foundersatwork.html",
      "http://www.paulgraham.com/foundervisa.html",
      "http://www.paulgraham.com/future.html",
      "http://www.paulgraham.com/gap.html",
      "http://www.paulgraham.com/good.html",
      "http://www.paulgraham.com/goodart.html",
      "http://www.paulgraham.com/hackernews.html",
      "http://www.paulgraham.com/head.html",
      "http://www.paulgraham.com/heroes.html",
      "http://www.paulgraham.com/hubs.html",
      "http://www.paulgraham.com/identity.html",
      "http://www.paulgraham.com/iflisp.html",
      "http://www.paulgraham.com/investors.html",
      "http://www.paulgraham.com/island.html",
      "http://www.paulgraham.com/javacover.html",
      "http://www.paulgraham.com/kate.html",
      "http://www.paulgraham.com/laundry.html",
      "http://www.paulgraham.com/lies.html",
      "http://www.paulgraham.com/mac.html",
      "http://www.paulgraham.com/makersschedule.html",
      "http://www.paulgraham.com/microsoft.html",
      "http://www.paulgraham.com/mit.html",
      "http://www.paulgraham.com/newthings.html",
      "http://www.paulgraham.com/noop.html",
      "http://www.paulgraham.com/nthings.html",
      "http://www.paulgraham.com/organic.html",
      "http://www.paulgraham.com/patentpledge.html",
      "http://www.paulgraham.com/philosophy.html",
      "http://www.paulgraham.com/polls.html",
      "http://www.paulgraham.com/prcmc.html",
      "http://www.paulgraham.com/property.html",
      "http://www.paulgraham.com/publishing.html",
      "http://www.paulgraham.com/ramenprofitable.html",
      "http://www.paulgraham.com/randomness.html",
      "http://www.paulgraham.com/really.html",
      "http://www.paulgraham.com/revolution.html",
      "http://www.paulgraham.com/schlep.html",
      "http://www.paulgraham.com/seesv.html",
      "http://www.paulgraham.com/segway.html",
      "http://www.paulgraham.com/selfindulgence.html",
      "http://www.paulgraham.com/sfp.html",
      "http://www.paulgraham.com/softwarepatents.html",
      "http://www.paulgraham.com/speak.html",
      "http://www.paulgraham.com/startuplessons.html",
      "http://www.paulgraham.com/superangels.html",
      "http://www.paulgraham.com/tablets.html",
      "http://www.paulgraham.com/usa.html",
      "http://www.paulgraham.com/vw.html",
      "http://www.paulgraham.com/web20.html",
      "http://www.paulgraham.com/whyyc.html",
      "http://www.paulgraham.com/wisdom.html",
      "http://www.paulgraham.com/word.html",
      "http://www.paulgraham.com/writing44.html",
      "http://www.paulgraham.com/yahoo.html",
      "http://www.paulgraham.com/ycombinator.html"
    ]
  end
end
