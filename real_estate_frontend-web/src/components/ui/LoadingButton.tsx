import type { ButtonHTMLAttributes } from "react";
import { LoaderCircle } from "lucide-react";

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  loading: boolean;
  loadingLabel?: string;
};

export function LoadingButton({ loading, loadingLabel = "Đang xử lý…", disabled, children, ...props }: Props) {
  return (
    <button {...props} disabled={disabled || loading} aria-busy={loading}>
      {loading ? <><LoaderCircle className="spin" aria-hidden="true" />{loadingLabel}</> : children}
    </button>
  );
}
