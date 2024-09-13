const ColorPickerHook = {
    mounted() {
      this.handleColorPicked = (event) => {
        if (event.detail.id === this.el.id) {
          this.pushEvent("eyedropper_color_picked", { color: event.detail.color });
        }
      };

      window.addEventListener('eyedropper:color-picked', this.handleColorPicked);
    },

    destroyed() {
      window.removeEventListener('eyedropper:color-picked', this.handleColorPicked);
    }
  };

  export default ColorPickerHook;