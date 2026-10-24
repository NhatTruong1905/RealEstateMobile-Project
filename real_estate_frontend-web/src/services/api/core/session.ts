const TOKEN_KEY = "real-estate-web-token";
let generation = 0;

function purge(storage: Storage) {
  for (let index = storage.length - 1; index >= 0; index--) {
    const key = storage.key(index);
    if (key?.startsWith("real-estate-web-")) storage.removeItem(key);
  }
}
function notifyCleared() {
  generation++;
  window.dispatchEvent(new Event("session-cleared"));
  window.dispatchEvent(new Event("favorites-change"));
  window.dispatchEvent(new Event("session-change"));
}
if (typeof window !== "undefined") window.addEventListener("storage", (event) => {
  if (event.storageArea !== localStorage || (event.key !== TOKEN_KEY && event.key !== null)) return;
  purge(sessionStorage);
  notifyCleared();
});

export const session = {
  get generation() { return generation; },
  get token() {
    return localStorage.getItem(TOKEN_KEY);
  },
  set(token: string) {
    generation++;
    localStorage.setItem(TOKEN_KEY, token);
    window.dispatchEvent(new Event("session-change"));
  },
  clear() {
    purge(localStorage);
    purge(sessionStorage);
    notifyCleared();
  },
};
