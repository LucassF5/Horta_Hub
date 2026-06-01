import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { prices: Object }

  selectProduct(event) {
    const item = event.target.closest("[data-sale-item]")
    const productId = event.target.value
    const priceField = item.querySelector("[data-price-field]")
    const priceDisplay = item.querySelector("[data-price-display]")

    if (productId && this.pricesValue[productId]) {
      const price = this.pricesValue[productId]
      priceField.value = price
      priceDisplay.textContent = `R$ ${Number(price).toFixed(2)}`
    } else {
      priceField.value = ""
      priceDisplay.textContent = "R$ —"
    }
  }
}
