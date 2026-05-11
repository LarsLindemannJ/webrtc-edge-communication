window.addEventListener("load", () => {
  setTimeout(() => {
    const audioBox =
      document.querySelector("#audioWidgetGrid .camera-audio-widget-body");

    const clientAudio = document.getElementById("clientAudio");

    if (!audioBox || !clientAudio) {
      console.warn("Audio force fix: fandt ikke audioBox eller clientAudio", {
        audioBox,
        clientAudio
      });
      return;
    }

    if (document.getElementById("forcedOperatorAudioLabel")) return;

    const label = document.createElement("div");
    label.id = "forcedOperatorAudioLabel";
    label.textContent = "Audio Operator";
    label.style.marginBottom = "6px";
    label.style.fontWeight = "700";

    clientAudio.style.width = "100%";
    clientAudio.style.marginBottom = "12px";

    audioBox.insertBefore(clientAudio, audioBox.firstChild);
    audioBox.insertBefore(label, clientAudio);
  }, 800);
});
