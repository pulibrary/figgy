# frozen_string_literal: true

adapter = Valkyrie::MetadataAdapter.find(:postgres)
resource = adapter.persister.save(resource: ScannedResource.new(title: "Test Title"))
resource_factory = adapter.query_service.resource_factory
orm_resource = adapter.query_service.resource_factory.from_resource(resource: resource)
resource_factory.to_resource(object: orm_resource)
result = RubyProf.profile do
  resource_factory.to_resource(object: orm_resource)
end

printer = RubyProf::CallStackPrinter.new(result)

printer.print(File.open("tmp/benchmark.html", "w"), {})

Benchmark.ips do |x|
  x.report("#to_resource") do
    resource_factory.to_resource(object: orm_resource)
  end
  x.report("#from_resource") do
    resource_factory.from_resource(resource: resource)
  end
end
