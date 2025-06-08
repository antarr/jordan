import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  updatePreview() {
    const url = this.inputTarget.value.trim()
    
    if (url && this.isValidImageUrl(url)) {
      const img = document.createElement("img")
      img.src = url
      img.className = "w-full h-full object-cover rounded-full"
      img.onerror = () => this.showDefaultAvatar()
      img.onload = () => {
        this.previewTarget.innerHTML = ""
        this.previewTarget.appendChild(img)
      }
    } else {
      this.showDefaultAvatar()
    }
  }

  showDefaultAvatar() {
    this.previewTarget.innerHTML = `
      <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
      </svg>
    `
  }

  isValidImageUrl(url) {
    try {
      new URL(url)
      return /\.(jpg|jpeg|png|gif|webp)$/i.test(url)
    } catch {
      return false
    }
  }
}