window.addEventListener("load", () => {
  setTimeout(() => {
    const statusEl = document.getElementById("status");
    const systemStatus = document.getElementById("systemStatus");

    [statusEl, systemStatus].forEach(el => {
      if (!el) return;

      if (!el.closest(".grid-stack-item-content")) {
        el.style.display = "none";
      }
    });
  }, 1200);
});
