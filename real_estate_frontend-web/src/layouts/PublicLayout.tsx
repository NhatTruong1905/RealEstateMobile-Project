import { RouteContent } from "../components/ui/RouteContent";
import { Footer } from "./Footer";
import { Header } from "./Header";

export function PublicLayout() {
  return (
    <>
      <Header />
      <main>
        <RouteContent />
      </main>
      <Footer />
    </>
  );
}
