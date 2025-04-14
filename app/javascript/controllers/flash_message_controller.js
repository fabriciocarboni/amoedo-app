// app/javascript/controllers/flash_message_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        // Ensure flash message is visible
        this.element.style.display = "block"

        // Auto-hide after 5 seconds
        setTimeout(() => {
            this.element.style.opacity = "0"
            this.element.style.transition = "opacity 5s"
            setTimeout(() => {
                this.element.remove()
            }, 1000)
        }, 5000)
    }
}