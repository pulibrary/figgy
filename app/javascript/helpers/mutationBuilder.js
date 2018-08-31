/*
 * MutationBuilder is a function that builds a dynamic Graphql mutation for Figgy.
 * It takes two parameters, a resource and any members in the form of filesets.
 * Example structure:
 * "resource": {
        "id": "4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d",
        "viewingDirection": "LEFTTORIGHT",
        "viewingHint": "paged",
        "startPage": "291b467b-36af-4d1e-80f1-dc76e8e250b9",
        "thumbnailId": "c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab",
        "memberIds": ["acb1c188-57c4-41cb-88e0-f44aca12e565", "c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab", "291b467b-36af-4d1e-80f1-dc76e8e250b9"]
    }
    "filesets": [
    {
        "id": "acb1c188-57c4-41cb-88e0-f44aca12e565",
        "label": "p. i",
        "viewingHint": "facing"
    },
    {
       "id": "c8376fd6-306c-4aed-b6a8-4eacbd2ca1ab",
       "label": "p. ii",
       "viewingHint": "single"
    }]
 *
*/
export default function MutationBuilder(resource, filesets) {
  this.filesetNum = filesets.length
  this.query_template = 'mutation UpdateResource(__inputs__: UpdateResourceInput!) { __mutations__ }'
  this.inputs = function() {
    let inputs = ['$input']
    for (let i=0; i < this.filesetNum; i++ ) {
      inputs.push('$fileset_' + i)
    }
    return inputs
  }
  this.mutations = function() {
    let mutations = []
    let mutation_template = '__mname__: updateResource(input: $__mname__) { resource { id, thumbnail { id, iiifServiceUrl, thumbnailUrl }, ... on ScannedResource { startPage, viewingHint, viewingDirection, members { id, label, thumbnail { id, thumbnailUrl, iiifServiceUrl } } }, ... on ScannedMap { startPage, viewingHint, viewingDirection, members { id, label, thumbnail { id, thumbnailUrl, iiifServiceUrl } } } }, errors }'
    let inputs = this.inputs()
    let mutationNum = inputs.length
    for (let i=0; i < mutationNum; i++ ) {
      mutations.push(mutation_template.replace(/__mname__/g, inputs[i]).substr(1))
    }
    return mutations
  }
  this.variables = function() {
    let variables = {}
    variables.input = resource
    for (let i=0; i < this.filesetNum; i++ ) {
      variables['fileset_' + i] = filesets[i]
    }
    return variables
  }
  this.build = function() {
      let request = this.query_template.replace('__inputs__', this.inputs().join(': UpdateResourceInput!,'))
      return request.replace('__mutations__', this.mutations().join())
  }
}
