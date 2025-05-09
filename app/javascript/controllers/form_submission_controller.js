// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["submitButton", "buttonText", "spinner"]

    connect() {
        this.form = this.element
        // Use a more specific event listener that's guaranteed to fire
        document.addEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
        document.addEventListener("turbo:load", this.resetOnPageLoad.bind(this))

        // Make sure spinner is hidden on connect
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.style.display = "none"
            this.spinnerTarget.classList.add("hidden")
        }
    }

    disconnect() {
        document.removeEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
        document.removeEventListener("turbo:load", this.resetOnPageLoad.bind(this))
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
        console.log("Reset called")
        this.submitting = false
        this.submitButtonTarget.disabled = false

        // Restore original appearance
        this.submitButtonTarget.classList.remove("bg-gray-300", "cursor-not-allowed") // Fixed class name
        this.submitButtonTarget.classList.add("bg-[#2965f6]", "hover:bg-blue-700")

        // Restore button text
        this.buttonTextTarget.textContent = "Upload e Processar"

        // Hide spinner
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.classList.add("hidden")
            this.spinnerTarget.style.display = "none"
        }
    }

    resetOnPageLoad() {
        // This ensures the button resets when the page loads after redirect
        this.reset()
    }

    handleTurboSubmitEnd(event) {
        console.log("Turbo submit end", event.detail.formSubmission.formElement, this.form)
        if (event.detail.formSubmission.formElement === this.form) {
            this.reset()
        }
    }
}