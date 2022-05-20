## Entry Point

When you go to a record's JSON-LD view (e.g https://figgy.princeton.edu/catalog/0b2ec178-347b-490b-8018-5ed9192db5c5.jsonld) the following module gets called: https://github.com/pulibrary/figgy/blob/c73bf406ed243be6f31159f72192ad9f747b84a6/app/models/concerns/linked_data.rb

The important piece of code is here: https://github.com/pulibrary/figgy/blob/c73bf406ed243be6f31159f72192ad9f747b84a6/app/models/concerns/linked_data.rb#L14-L16

## `LinkedData::LinkedResourceFactory`

The `LinkedData::LinkedResourceFactory` abstracts away the fact that different types of resources might need different properties to display in the JSON-LD. The relevant switch can be found here: https://github.com/pulibrary/figgy/blob/c73bf406ed243be6f31159f72192ad9f747b84a6/app/models/concerns/linked_data/linked_resource_factory.rb#L10-L26

## Base Class: `LinkedData::LinkedResource`

Most of the classes present in the above switch inherit from `LinkedData::LinkedResource`. As can be seen in the `LinkedData` module, however, the only important thing is that the instance responds to `#to_jsonld` and returns a JSON representation of the linked data.

`LinkedData::LinkedResource` abstracts this further by expecting that subclasses implement a `#properties` method, which will get added to the JSON-LD. As such, most subclasses will override that method like so: https://github.com/pulibrary/figgy/blob/c73bf406ed243be6f31159f72192ad9f747b84a6/app/models/concerns/linked_data/linked_ephemera_folder.rb#L102-L136

## Tutorial: Add a property to all records' JSON-LD.

### Add a test.

Open up `spec/models/linked_data/linked_resource_factory_spec.rb` and add a spec like this:

```ruby
    context "with a scanned resource" do
      let(:linked_resource) { described_class.new(resource: resource).new }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
      before do
        Timecop.freeze
      end
      it "returns JSON-LD with a system_created_at date" do
        expect(linked_resource.as_jsonld["system_created_at"]).to be_present
      end
    end
```

### Add the property

Open up `app/models/concerns/linked_data/linked_resource.rb` and add a property to either `linked_properties` or `properties`. In this case it will be added to `linked_properties`, which doesn't get overridden.

```ruby
      def linked_properties
        {
          '@context': "https://bibdata.princeton.edu/context.json",
          '@id': url,
          identifier: resource.try(:identifier),
          scopeNote: resource.try(:portion_note),
          navDate: resource.try(:nav_date),
          edm_rights: linked_rights,
          memberOf: linked_collections,
          system_created_at: resource.try(:created_at)
        }.merge(properties)
      end
```