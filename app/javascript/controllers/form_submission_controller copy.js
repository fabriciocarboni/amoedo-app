// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["submitButton", "buttonText", "spinner"]

    connect() {
        this.form = this.element
        document.addEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))

        // Make sure spinner is hidden on connect
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.style.display = "none"
            this.spinnerTarget.classList.add("hidden")
        }
    }

    disconnect() {
        document.removeEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
    }

    initialize() {
        this.submitting = false
    }

    submit(event) {
        if (this.submitting) {
            event.preventDefault()
            return
        }

        this.submitting = true
        this.submitButtonTarget.disabled = true

        // Add disabled appearance
        this.submitButtonTarget.classList.remove("bg-[#2965f6]", "hover:bg-blue-700")
        this.submitButtonTarget.classList.add("bg-gray-300", "cursor-not-allowed")

        // Change button text
        this.buttonTextTarget.textContent = "Processando..."

        // Show spinner
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.classList.remove("hidden")
            this.spinnerTarget.style.display = "inline-block"
        }
    }

    reset() {
        this.submitting = false
        this.submitButtonTarget.disabled = false

        // Restore original appearance
        this.submitButtonTarget.classList.remove("bg-gray-400", "cursor-not-allowed")
        this.submitButtonTarget.classList.add("bg-[#2965f6]", "hover:bg-blue-700")

        // Restore button text
        this.buttonTextTarget.textContent = "Upload e Processar"

        // Hide spinner
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.classList.add("hidden")
            this.spinnerTarget.style.display = "none"
        }
    }

    handleTurboSubmitEnd(event) {
        if (event.detail.formSubmission.formElement === this.form) {
            this.reset()
        }
    }
}