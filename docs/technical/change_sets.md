ChangeSets in Figgy are used to control how metadata gets attached to a resource. They control which workflow is used, which properties can be written to in a given scenario, and which fields display in a form. A single model may have multiple ChangeSets if there are multiple forms that go into a single model, as is the case for `ScannedResourceChangeSet` and `SimpleResourceChangeSet`.

## Getting a ChangeSet from a Resource

`DynamicChangeSet` will always return the appropriate `ChangeSet` for an item loaded from a database.

```ruby
resource = query_service.find_by(id: id)
change_set = DynamicChangeSet.new(resource)
```

## Assigning properties to a ChangeSet by feature

A few shortcuts were added to `ChangeSet` in figgy to enable adding required properties and validations by feature. They're the following:

### core_resource

```ruby
class PhotographChangeSet < ChangeSet
  core_resource(change_set: "photograph")
end
```

Adds the properties necessary to pass the change_set shared specs in Figgy, and if the `change_set` parameter is given it adds the `change_set` property necessary for a model having multiple ChangeSets.

### enable_order_manager

```ruby
class PhotographChangeSet < ChangeSet
  enable_order_manager
end
```

Adds properties such as viewing_hint, viewing_direction, member_ids, nav_date, thumbnail_id, and start_canvas as well as their validations to enable the order manager to work.

### enable_pdf_support

```ruby
class PhotographChangeSet < ChangeSet
  enable_pdf_support
end
```

Adds `pdf_type` and `file_metadata` to the ChangeSet properties to enable PDF downloads and caching to work.

### feature_terms

When a feature is enabled via the above helpers, it adds some keys to the class attribute `feature_terms`. This can be used to populate `primary_terms` so the form renders with the features you've enabled.

Example:

```ruby
class PhotographChangeSet < ChangeSet
  core_resource(change_set: "photograph")
  enable_pdf_support

  def primary_terms
    feature_terms.dup # Now the form will render with title, rights_statement, rights_note, pdf_type, and the required hidden change_set property.
  end
end
```

## Multiple ChangeSets for one model

`ScannedResourceChangeSet` and `SimpleResourceChangeSet` both point to `ScannedResource`, the difference being which workflow is used and the fact that `ScannedResourceChangeSet` imports metadata, while there must be a form for `SimpleResourceChangeSet`.

When a `ScannedResource` is saved with a `SimpleResourceChangeSet` it sets the `change_set` property to equal "simple".

### Routing

```ruby
  resources :scanned_resources do
    collection do
      get "new/:change_set", to: "scanned_resources#new"
    end
  end
```