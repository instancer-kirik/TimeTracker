export function initStandardEyedropper() {
    let eyedropperActive = false;
  
    window.addEventListener('phx:toggle_eyedropper', (event) => {
      const colorPickerId = event.detail.id;
      const eyedropper = new EyeDropper();
  
      console.log("Attempting to toggle eyedropper...");
  
      if (!eyedropperActive) {
        eyedropperActive = true;
        console.log("Opening eyedropper...");
        eyedropper.open().then(result => {
          const color = result.sRGBHex;
          console.log("Picked color:", color);
          const colorPicker = document.getElementById(colorPickerId);
          if (colorPicker) {
            const hexInput = colorPicker.querySelector('input[name="hex"]');
            if (hexInput) {
              hexInput.value = color;
              hexInput.dispatchEvent(new Event('input', { bubbles: true }));
              hexInput.dispatchEvent(new Event('change', { bubbles: true }));
            }
          }
        }).catch(error => {
          console.error('EyeDropper error:', error);
        }).finally(() => {
          eyedropperActive = false;
        });
      }
    });
  }