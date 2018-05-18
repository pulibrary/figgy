import manifest from "./mock-manifest"

const axios = {
  get: () => new Promise(res => res({ data: manifest }) ),
  defaults: { headers: { common: { 'X-CSRF-Token': null, 'Accept': null } } },
  patch: () => new Promise(res => res({ status: 200 }) ),
  all: () => new Promise(res => res({ data: 'all' }) )
}
export default axios
