import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { prices: Object }

  connect() {
    this.recalculateAll()
  }

  selectProduct(event) {
    const item = event.target.closest("[data-sale-item]")
    const productId = event.target.value
    const priceField = item.querySelector("[data-price-field]")
    const priceDisplay = item.querySelector("[data-price-display]")

    if (productId && this.pricesValue[productId]) {
      const price = this.pricesValue[productId]
      priceField.value = price
      priceDisplay.textContent = this.formatCurrency(price)
    } else {
      priceField.value = ""
      priceDisplay.textContent = "R$ -"
    }

    this.recalculateItem(item)
    this.recalculateTotal()
  }

  quantityChanged(event) {
    const item = event.target.closest("[data-sale-item]")

    this.recalculateItem(item)
    this.recalculateTotal()
  }

  removeItem(event) {
    const item = event.target.closest("[data-sale-item]")
    const destroyField = item.querySelector("[data-destroy-field]")
    const idField = item.querySelector("input[name$='[id]']")

    if (idField) {
      destroyField.value = "1"
      item.hidden = true
    } else {
      item.remove()
    }

    this.recalculateTotal()
  }

  recalculateAll() {
    this.items.forEach((item) => this.recalculateItem(item))
    this.recalculateTotal()
  }

  recalculateItem(item) {
    const subtotalDisplay = item.querySelector("[data-subtotal-display]")
    if (!subtotalDisplay) return

    subtotalDisplay.textContent = this.formatCurrency(this.itemSubtotal(item))
  }

  recalculateTotal() {
    const total = this.items.reduce((sum, item) => sum + this.itemSubtotal(item), 0)
    const totalDisplay = this.element.querySelector("[data-sale-total]")

    if (totalDisplay) totalDisplay.textContent = this.formatCurrency(total)
  }

  itemSubtotal(item) {
    if (this.markedForDestruction(item)) return 0

    const quantity = Number(item.querySelector("[data-quantity-field]")?.value || 0)
    const price = Number(item.querySelector("[data-price-field]")?.value || 0)

    return quantity * price
  }

  markedForDestruction(item) {
    return item.querySelector("[data-destroy-field]")?.value === "1"
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL"
    }).format(Number(value || 0))
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-sale-item]"))
  }
}
