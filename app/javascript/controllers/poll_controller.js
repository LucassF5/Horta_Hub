import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Busca o elemento atualizado em turbo_stream a cada intervalo. A resposta
// substitui o elemento, o que reconecta este controller e agenda a próxima
// busca; quando a resposta vem sem data-controller="poll", o polling para.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this.onVisibilityChange = this.onVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.onVisibilityChange)
    this.schedule()
  }

  disconnect() {
    clearTimeout(this.timer)
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
  }

  schedule() {
    clearTimeout(this.timer)
    if (document.hidden) return

    this.timer = setTimeout(() => this.refresh(), this.intervalValue)
  }

  onVisibilityChange() {
    if (document.hidden) {
      clearTimeout(this.timer)
    } else {
      this.refresh()
    }
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        credentials: "same-origin"
      })
      const contentType = response.headers.get("Content-Type") || ""

      if (response.ok && contentType.includes("turbo-stream")) {
        Turbo.renderStreamMessage(await response.text())
        return
      }

      // Sessão expirada ou sem permissão (redirect para HTML) e erros 4xx:
      // tentar de novo não resolve, então o polling para.
      if (response.status < 500) return
    } catch (error) {
      // Falha de rede: tenta de novo no próximo intervalo.
    }

    if (this.element.isConnected) this.schedule()
  }
}
