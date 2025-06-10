import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "error"]
  static values = { maxSize: Number }

  connect() {
    this.maxSizeValue = this.maxSizeValue || 5242880 // 5MB default
  }

  preview() {
    const file = this.inputTarget.files[0]
    this.clearError()
    
    if (!file) {
      return
    }

    // Validate file size
    if (file.size > this.maxSizeValue) {
      this.showError("File size must be less than 5MB")
      this.inputTarget.value = ""
      return
    }
    
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        this.updatePreview(e.target.result)
      }
      
      reader.readAsDataURL(file)
    } else {
      this.showError("Please select a valid image file")
      this.inputTarget.value = ""
    }
  }

  updatePreview(src) {
    const img = document.createElement("img")
    img.src = src
    img.className = "h-24 w-24 object-cover rounded-full ring-2 ring-gray-200"
    
    this.previewTarget.innerHTML = ""
    this.previewTarget.appendChild(img)
  }

  showDefaultAvatar() {
    this.previewTarget.innerHTML = `
      <div class="h-24 w-24 rounded-full bg-gray-100 ring-2 ring-gray-200 flex items-center justify-center">
        <svg class="h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
        </svg>
      </div>
    `
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }
}