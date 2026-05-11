window.addEventListener("load", () => {
  setTimeout(() => {

    const titles = [
      "GPS / Lokation",
      "Batteri",
      "Telefontype",
      "Enhed",
      "Netværk / IP"
    ];

    document.querySelectorAll("*").forEach(el => {
      const txt = (el.innerText || el.textContent || "").trim();

      if (
        titles.includes(txt) &&
        !el.closest(".grid-stack-item-content")
      ) {
        el.remove();
      }
    });

  }, 1200);
});
