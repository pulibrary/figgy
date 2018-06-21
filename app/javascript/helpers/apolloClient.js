import { ApolloClient } from 'apollo-client'
import { createHttpLink } from 'apollo-link-http'
import { InMemoryCache } from 'apollo-cache-inmemory'
const csrfToken = document.getElementsByName('csrf-token')[0].content
const httpLink = createHttpLink({
  uri: '/graphql',
  credentials: 'include',
  headers: {
    'X-CSRF-Token': csrfToken
  }
})

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache()
})

export default client
