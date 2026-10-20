import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  async copy(event) {
    const button = event.currentTarget
    await navigator.clipboard.writeText(this.sourceTarget.value)
    button.textContent = "Copiado!"
  }
}
