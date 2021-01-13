defmodule ChatApi.CompaniesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Companies

  describe "companies" do
    alias ChatApi.Companies.Company

    @update_attrs %{
      description: "some updated description",
      external_id: "some updated external_id",
      industry: "some updated industry",
      logo_image_url: "some updated logo_image_url",
      metadata: %{},
      name: "some updated name",
      slack_channel_id: "some updated slack_channel_id",
      slack_channel_name: "some updated slack_channel_name",
      website_url: "some updated website_url"
    }
    @invalid_attrs %{
      description: nil,
      external_id: nil,
      industry: nil,
      logo_image_url: nil,
      metadata: nil,
      name: nil,
      slack_channel_id: nil,
      slack_channel_name: nil,
      website_url: nil
    }

    setup do
      account = insert(:account)
      company = insert(:company, account: account)

      {:ok, account: account, company: company}
    end

    test "list_companies/1 returns all companies", %{account: account, company: company} do
      company_ids =
        Companies.list_companies(account.id)
        |> Enum.map(& &1.id)

      assert company_ids == [company.id]
    end

    test "get_company!/1 returns the company with given id", %{company: company} do
      found_company =
        Companies.get_company!(company.id)
        |> Repo.preload([:account])

      assert found_company == company
    end

    test "create_company/1 with valid data creates a company", %{account: account} do
      attrs = params_with_assocs(:company, account: account, name: "Test Co")

      assert {:ok, %Company{name: "Test Co"}} = Companies.create_company(attrs)
    end

    test "create_company/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(@invalid_attrs)
    end

    test "update_company/2 with valid data updates the company", %{company: company} do
      assert {:ok, %Company{} = company} = Companies.update_company(company, @update_attrs)

      assert company.description == "some updated description"
      assert company.external_id == "some updated external_id"
      assert company.industry == "some updated industry"
      assert company.logo_image_url == "some updated logo_image_url"
      assert company.name == "some updated name"
      assert company.slack_channel_id == "some updated slack_channel_id"
      assert company.slack_channel_name == "some updated slack_channel_name"
      assert company.website_url == "some updated website_url"
      assert company.metadata == %{}
    end

    test "update_company/2 with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} = Companies.update_company(company, @invalid_attrs)
      assert company == Companies.get_company!(company.id) |> Repo.preload([:account])
    end

    test "delete_company/1 deletes the company", %{company: company} do
      assert {:ok, %Company{}} = Companies.delete_company(company)
      assert_raise Ecto.NoResultsError, fn -> Companies.get_company!(company.id) end
    end

    test "change_company/1 returns a company changeset", %{company: company} do
      assert %Ecto.Changeset{} = Companies.change_company(company)
    end

    test "find_by_slack_channel/2 finds an account's company by slack_channel_id", %{
      account: account
    } do
      company = insert(:company, account: account, slack_channel_id: "C1")
      _company_2 = insert(:company, account: account, slack_channel_id: "C2")
      _company_3 = insert(:company, account: account, slack_channel_id: "C3")

      assert %Company{id: company_id, slack_channel_id: "C1"} =
               Companies.find_by_slack_channel(account.id, "C1")

      assert company.id == company_id
    end
  end
end
