// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    connect() {
        if (this.element.dataset.showModal === "true") {
            this.showModal()
        }
    }

    showModal() {
        const modalElement = this.modalTarget

        // Make modal visible
        modalElement.classList.remove('hidden')
        modalElement.classList.add('flex')

        // Add backdrop with very low opacity (almost transparent)
        document.body.classList.add('overflow-hidden')
        const backdrop = document.createElement('div')
        backdrop.id = 'modal-backdrop'
        backdrop.className = 'fixed inset-0 bg-gray-400 bg-opacity-10 z-40' // Very light gray with just 10% opacity
        document.body.appendChild(backdrop)

        // Add event listeners to close modal
        this.addCloseListeners()

        // Add backdrop click to close
        backdrop.addEventListener('click', () => this.closeModal())
    }

    closeModal() {
        const modalElement = this.modalTarget

        // Hide modal
        modalElement.classList.add('hidden')
        modalElement.classList.remove('flex')

        // Remove backdrop
        document.body.classList.remove('overflow-hidden')
        const backdrop = document.getElementById('modal-backdrop')
        if (backdrop) backdrop.remove()
    }

    addCloseListeners() {
        // Add close functionality to all close buttons
        const closeButtons = this.element.querySelectorAll('[data-action="modal#close"]')
        closeButtons.forEach(button => {
            button.addEventListener('click', () => this.closeModal())
        })

        // Add ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') this.closeModal()
        })
    }
}