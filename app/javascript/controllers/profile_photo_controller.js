import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  updatePreview() {
    const file = this.inputTarget.files[0]
    
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "w-full h-full object-cover"
        
        this.previewTarget.innerHTML = ""
        this.previewTarget.appendChild(img)
      }
      
      reader.readAsDataURL(file)
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
}