defmodule Figx.Member do
  alias Figx.{Repo, Resource}
  import Ecto.Query

  # Ecto means we can't just write SQL - the following is a complicated way of
  # writing:
  #
  # SELECT member.* FROM orm_resources a,
  #   jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS  ```
  #   b(member, member_pos)
  #   JOIN orm_resources member ON
  #   (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
  #   ORDER BY b.member_pos
  def members(id) when is_binary(id) do
    Resource
    |> cross_join_member_ids()
    |> join_resources_on_member_id()
    # Select all member properties.
    |> select([..., member], member)
    # Order by the order of member_ids.
    |> order_by([orm_resources, orm_resources_2, member], orm_resources_2.ordinality)
    # Only find the resource with the given ID, makes the cross join not
    # expensive.
    |> where([orm_resources], orm_resources.id == ^id)
    |> Repo.all()
  end

  # Membership is in parents as {"member_ids": [{"id": "1"}, {"id": "2"}]}
  # This creates a result set that joins all resources with every member ID,
  # such that given a record with ID 1, member_ids: [{"id": "1"}, {"id": "2"}]
  # you get two rows, one is ID 1, member {"id": "1"} and another which is ID 1,
  # member {"id": "2"}
  defp cross_join_member_ids(query) do
    query
    |> join(
      :cross,
      [orm_resources],
      orm_resources_2 in fragment("jsonb_array_elements(?.metadata->'member_ids') WITH ORDINALITY", orm_resources)
    )
  end

  # Joins all the member properties for every row which is a parent, member id
  # combo.
  defp join_resources_on_member_id(query) do
    query
    |> join(:left, [orm_resources, orm_resources_2, member], member in Resource,
      on: fragment("(?.value->>'id')::UUID", orm_resources_2) == member.id
    )
  end
end
