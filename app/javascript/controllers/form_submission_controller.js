// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["submitButton", "buttonText", "spinner"]

    connect() {
        this.form = this.element
        // Store original button text
        if (this.hasButtonTextTarget) {
            this.originalButtonText = this.buttonTextTarget.textContent
        }

        // Check if this form uses Turbo
        this.usesTurbo = this.form.getAttribute('data-turbo') !== 'false'

        // Only add Turbo event listeners for Turbo-enabled forms
        if (this.usesTurbo) {
            this.turboSubmitEndHandler = this.handleTurboSubmitEnd.bind(this)
            document.addEventListener("turbo:submit-end", this.turboSubmitEndHandler)
        }

        // Make sure spinner is hidden on connect
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.style.display = "none"
            this.spinnerTarget.classList.add("hidden")
        }
    }

    disconnect() {
        if (this.usesTurbo && this.turboSubmitEndHandler) {
            document.removeEventListener("turbo:submit-end", this.turboSubmitEndHandler)
        }
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
        if (this.hasButtonTextTarget) {
            this.buttonTextTarget.textContent = "Processando..."
        }

        // Show spinner
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.classList.remove("hidden")
            this.spinnerTarget.style.display = "inline-block"
        }

        // For non-Turbo forms, the page will redirect, so no need to reset
        if (!this.usesTurbo) {
            // Let the browser handle the form submission normally
            return
        }
    }

    reset() {
        console.log("Reset called")
        this.submitting = false
        this.submitButtonTarget.disabled = false

        // Restore original appearance
        this.submitButtonTarget.classList.remove("bg-gray-300", "cursor-not-allowed")
        this.submitButtonTarget.classList.add("bg-[#2965f6]", "hover:bg-blue-700")

        // Restore original button text
        if (this.hasButtonTextTarget && this.originalButtonText) {
            this.buttonTextTarget.textContent = this.originalButtonText
        }

        // Hide spinner
        if (this.hasSpinnerTarget) {
            this.spinnerTarget.classList.add("hidden")
            this.spinnerTarget.style.display = "none"
        }
    }

    handleTurboSubmitEnd(event) {
        console.log("Turbo submit end", event.detail.formSubmission.formElement, this.form)
        if (event.detail.formSubmission.formElement === this.form) {
            this.reset()
        }
    }
}
