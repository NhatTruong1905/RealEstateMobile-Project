const TOKEN_KEY = "real-estate-web-token";

export const session = {
  get token() {
    return localStorage.getItem(TOKEN_KEY);
  },
  set(token: string) {
    localStorage.setItem(TOKEN_KEY, token);
    window.dispatchEvent(new Event("session-change"));
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY);
    window.dispatchEvent(new Event("session-change"));
  },
};
