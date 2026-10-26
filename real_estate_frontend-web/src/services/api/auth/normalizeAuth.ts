export function normalizeAuthField(name: string, value: string): string {
  if (name === "password" || name === "confirmPassword") return value;
  if (name === "fullname") return value.trim().replace(/\s+/gu, " ");
  if (name === "phone") return value.replace(/\s/gu, "");
  return value.trim();
}
