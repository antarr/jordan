import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "counter", "submit"]

  connect() {
    this.updateCount()
  }

  updateCount() {
    const text = this.textareaTarget.value.trim()
    const words = text === "" ? 0 : text.split(/\s+/).length
    
    this.counterTarget.textContent = `${words} words`
    
    if (words >= 25) {
      this.counterTarget.classList.remove("text-red-500")
      this.counterTarget.classList.add("text-green-600")
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
    } else {
      this.counterTarget.classList.remove("text-green-600")
      this.counterTarget.classList.add("text-red-500")
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
}