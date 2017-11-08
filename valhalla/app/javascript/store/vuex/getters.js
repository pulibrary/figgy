// getters
const getters = {
  imageIdList: state => {
    return state.images.map(image => image.id)
  },
  orderChanged: state => {
    var ogOrder = JSON.stringify(state.ogImages.map(img => img.id))
    var imgOrder = JSON.stringify(state.images.map(img => img.id))
    return ogOrder !== imgOrder
  },
  stateChanged: (state,getters) => {
    var propsChanged = []
    propsChanged.push(state.ogState.thumbnail !== state.thumbnail)
    propsChanged.push(state.ogState.startPage !== state.startPage)
    propsChanged.push(state.ogState.viewingHint !== state.viewingHint)
    propsChanged.push(state.ogState.viewingDirection !== state.viewingDirection)
    propsChanged.push(state.changeList.length > 0)
    propsChanged.push(getters.orderChanged)
    if (propsChanged.indexOf(true) > -1) {
      return true
    } else {
      return false
    }
  }
}

export default getters
