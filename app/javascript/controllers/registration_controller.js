import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]

  connect() {
    this.updateSubmitButton()
  }

  selectContactMethod(event) {
    this.updateSubmitButton()
  }

  updateSubmitButton() {
    const selectedMethod = this.element.querySelector('input[name="contact_method"]:checked')
    const submitButton = this.submitButtonTarget
    
    if (selectedMethod) {
      submitButton.disabled = false
      submitButton.classList.remove("opacity-50", "cursor-not-allowed")
    } else {
      submitButton.disabled = true
      submitButton.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
}