# 5. Data Migrations

Date: 2015-12-19

## Status

Accepted

## Context

Different real-world resources are modeled in different ways in figgy, using different hierarchical combinations of Resources and File Sets. However, certain functionality across different types of resources has been implemented under the assumption that any Resource may not be a child of more than one other resource.

Examples of features that rely on this:
- [Visibility and State propagation](https://github.com/pulibrary/figgy/blob/71e2b7abd9213779dc06530af0bb43c8ec054989/app/change_set_persisters/change_set_persister/propagate_visibility_and_state.rb): If a resource had two parents we wouldn't know which should provide these values for propagation.
- [Preservation](https://github.com/pulibrary/figgy/blob/main/app/services/preserver.rb): If a resource had multiple parents its entire tree would be preserved multiple times, or we'd otherwise need to decide which parent would preserve which children
- Breadcrumb display
- Cascading deletion
- Any scenario where the metadata of a resource is determined by checking the parent, e.g., `coverage_from_parent`


## Decisions

Each resource may have only 0 or 1 parent objects.

Note that a collection is not a parent object (membership in a collection is stored on a resource itself, not on a collection's member_ids property. A resource can belong to multiple collections.

## Consequences

- We can safely implement features that only work when there is a maximum of 1 parent for a given resource.
- Modeling that might benefit from a resource having more than one parent resource is not feasible.
