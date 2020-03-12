export default function setupAuthLinkClipboard () {
  let div = document.getElementById('clipboard-trigger-holder')
  if (div) {
    div.innerHTML = '<button class="btn btn-primary" id="clipboard-trigger">Copy link to clipboard</button>'
  }

  new ClipboardJS('#clipboard-trigger', {
    text: function (trigger) {
      let url = document.getElementById('authorized-link').children[0].getAttribute('href')
      return url
    }
  })
}
