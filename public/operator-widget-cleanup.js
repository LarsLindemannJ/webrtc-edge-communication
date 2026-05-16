window.addEventListener("load", () => {
  setTimeout(() => {

    const textsToHide = [
      "Operator-lyd",
      "Operator-lyd hos klient",
      "Kamera-vælger"
    ];

    const elements = Array.from(
      document.querySelectorAll("div,h1,h2,h3,h4,p,span")
    );

    elements.forEach(el => {
      const txt = (el.innerText || el.textContent || "").trim();

      if (textsToHide.includes(txt)) {
        el.style.display = "none";
      }
    });

    const oldCameraSelector =
      Array.from(document.querySelectorAll("*"))
      .find(el =>
        (el.innerText || "").includes("Vis stream") &&
        (el.innerText || "").includes("Skjul/sluk")
      );

    if (oldCameraSelector) {
      oldCameraSelector.style.display = "none";
    }

  }, 1200);
});
