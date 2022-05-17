import { ApolloClient } from 'apollo-client'
import { createHttpLink } from 'apollo-link-http'
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory'
const csrfToken = document.getElementsByName('csrf-token')[0]
  ? document.getElementsByName('csrf-token')[0].content : undefined
const httpLink = createHttpLink({
  uri: '/graphql',
  credentials: 'include',
  headers: {
    'X-CSRF-Token': csrfToken
  }
})

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData: {
    __schema: {
      types: [
        {
          kind: "INTERFACE",
          name: "Resource",
          possibleTypes: [
            { name: "FileSet" },
            { name: "ScannedResource" },
            { name: "ScannedMap" },
          ],
        },
      ],
    },
  }
})

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache({ fragmentMatcher })
})

export default client
