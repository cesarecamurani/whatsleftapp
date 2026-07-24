import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["chipList", "input", "hiddenContainer", "clearButton"]
  static values = {
    ingredients: Array,
    maxIngredients: Number,
    minIngredientLength: Number,
    maxIngredientLength: Number
  }

  connect() {
    this.inputTarget.removeAttribute("name")
    this.ingredientsValue.forEach((ingredient) => this.addChip(ingredient))
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()

      if (this.inputTarget.value.trim() === "") {
        this.element.requestSubmit()
      } else {
        this.commitInput()
      }

      return
    }

    if (
      event.key === "Backspace" &&
      this.inputTarget.value === "" &&
      this.chips.length > 0
    ) {
      this.removeChip(this.chips[this.chips.length - 1])
    }
  }

  input(event) {
    this.inputTarget.setCustomValidity("")

    const value = event.target.value

    if (value.includes(",")) {
      const parts = value.split(",")
      const remainder = parts.pop()

      this.addValues(parts)
      this.inputTarget.value = remainder
    }

    this.updateClearButton()
  }

  paste(event) {
    const text = event.clipboardData.getData("text")

    if (!text.includes(",") && !text.includes("\n")) {
      return
    }

    event.preventDefault()
    this.addValues(text.split(/[,\n]+/))
  }

  submit() {
    this.commitInput()
  }

  clear(event) {
    event.preventDefault()

    this.chipListTarget.replaceChildren()
    this.inputTarget.value = ""
    this.syncHiddenInputs()
    this.updateClearButton()

    Turbo.visit(this.element.action)
  }

  remove(event) {
    event.preventDefault()
    this.removeChip(event.currentTarget.closest("[data-chip]"))
  }

  commitInput() {
    const value = this.inputTarget.value.trim()

    if (
      value !== "" &&
      value.length < this.minIngredientLengthValue
    ) {
      this.inputTarget.setCustomValidity(
        `Use at least ${this.minIngredientLengthValue} characters per ingredient.`
      )
      this.inputTarget.reportValidity()
      return
    }

    this.inputTarget.setCustomValidity("")
    this.addChip(this.inputTarget.value)
    this.inputTarget.value = ""
    this.updateClearButton()
  }

  addValues(values) {
    values.forEach((value) => this.addChip(value))
  }

  addChip(rawValue) {
    const value = rawValue.toString().trim().toLowerCase()

    if (
      value === "" ||
      value.length < this.minIngredientLengthValue ||
      value.length > this.maxIngredientLengthValue ||
      this.chips.length >= this.maxIngredientsValue ||
      this.hasChip(value)
    ) {
      return
    }

    const chip = document.createElement("span")
    chip.className = "chip"
    chip.dataset.chip = value

    const label = document.createElement("span")
    label.className = "chip-label"
    label.textContent = value

    const removeButton = document.createElement("button")
    removeButton.type = "button"
    removeButton.className = "chip-remove"
    removeButton.dataset.action = "ingredient-chips#remove"
    removeButton.setAttribute("aria-label", `Remove ${value}`)
    removeButton.textContent = "×"

    chip.append(label, removeButton)
    this.chipListTarget.append(chip)

    this.syncHiddenInputs()
    this.updateClearButton()
  }

  removeChip(chip) {
    if (!chip) {
      return
    }

    chip.remove()
    this.syncHiddenInputs()
    this.updateClearButton()
  }

  hasChip(value) {
    return this.chips.some((chip) => chip.dataset.chip === value)
  }

  syncHiddenInputs() {
    this.hiddenContainerTarget.replaceChildren()

    this.chips.forEach((chip) => {
      const input = document.createElement("input")

      input.type = "hidden"
      input.name = "ingredients[]"
      input.value = chip.dataset.chip

      this.hiddenContainerTarget.append(input)
    })
  }

  updateClearButton() {
    if (!this.hasClearButtonTarget) {
      return
    }

    const hasContent =
      this.chips.length > 0 ||
      this.inputTarget.value.trim() !== ""

    this.clearButtonTarget.hidden = !hasContent
  }

  get chips() {
    return Array.from(
      this.chipListTarget.querySelectorAll("[data-chip]")
    )
  }
}
