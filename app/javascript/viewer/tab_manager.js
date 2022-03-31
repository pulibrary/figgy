export default class TabManager {
  initialize () {
    this.bindTabs()
  }

  bindTabs () {
    this.onTabSelect(this.focusTab.bind(this))
  }

  onTabSelect (fn) {
    for (let i = 0; i < this.tabs.length; i++) {
      this.tabs[i].addEventListener('click', fn)
    }
  }

  focusTab (tabClickEvent) {
    for (let i = 0; i < this.tabs.length; i++) {
      this.tabs[i].classList.remove('active')
    }
    var clickedTab = tabClickEvent.currentTarget
    clickedTab.classList.add('active')
    tabClickEvent.preventDefault()
    var ContentPanes = document.querySelectorAll('.tab-pane')
    for (let i = 0; i < ContentPanes.length; i++) {
      ContentPanes[i].classList.remove('active')
    }
    var anchorReference = tabClickEvent.target
    var activePaneId = anchorReference.getAttribute('href')
    var activePane = document.querySelector(activePaneId)
    activePane.classList.add('active')
  }

  get tabs () {
    return document.querySelectorAll('ul.nav-tabs > li')
  }
}
