document.addEventListener("click", (event) => {
  const dismiss = event.target.closest("[data-dismiss]");
  if (dismiss) dismiss.closest(".flash").remove();
  const step = event.target.closest("[data-step]");
  if (step) {
    const input = step.closest(".quantity-stepper").querySelector("input");
    const value = Number(input.value) || 1;
    input.value = Math.min(
      Number(input.max),
      Math.max(Number(input.min), value + Number(step.dataset.step)),
    );
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }
  if (event.target.closest("#fill-sample")) {
    const sample = {
      name: "余白 花子",
      email: "demo@example.com",
      postal_code: "100-0001",
      prefecture: "東京都",
      address: "千代田区 サンプル町1-2-3 デモハイツ101",
    };
    Object.entries(sample).forEach(([key, value]) => {
      document.getElementById(`order_${key}`).value = value;
    });
    document.getElementById("order_name").focus();
  }
});
document.addEventListener("submit", (event) => {
  if (event.target.id !== "checkout-form") return;
  const button = document.getElementById("place-order");
  button.disabled = true;
  button.textContent = "ご注文を処理しています…";
});
window.addEventListener("pageshow", () => {
  const button = document.getElementById("place-order");
  if (button) {
    button.disabled = false;
    button.textContent = "デモ注文を確定する";
  }
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    document.querySelectorAll(".search-menu[open]").forEach((details) => {
      details.open = false;
      details.querySelector("summary").focus();
    });
  }
});

document.addEventListener("submit", (event) => {
  const message = event.target.dataset.confirmMessage;
  if (message && !window.confirm(message)) event.preventDefault();
});
