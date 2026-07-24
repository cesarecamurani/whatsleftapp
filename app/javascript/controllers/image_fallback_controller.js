import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const image = this.element.querySelector("img")

    if (image?.complete && image.naturalWidth === 0) {
      this.show()
    }
  }

  show() {
    this.element.classList.add("image-frame--fallback")
  }
}
