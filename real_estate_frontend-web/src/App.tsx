import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { PublicLayout } from "./layouts/PublicLayout";
import { SellerLayout } from "./layouts/SellerLayout";
import { ProtectedRoute } from "./routes/ProtectedRoute";
import { AccountPage } from "./screens/account/AccountScreen";
import { SavedPage } from "./screens/account/SavedScreen";
import { AuthPage } from "./screens/auth/AuthScreen";
import { NotFound, SimplePage } from "./screens/common/CommonScreens";
import { HomePage } from "./screens/home/HomeScreen";
import { PropertiesPage } from "./screens/properties/PropertiesScreen";
import { PropertyDetailPage } from "./screens/properties/PropertyDetailScreen";
import { PostProperty } from "./screens/seller/PostPropertyScreen";
import { SellerOverview } from "./screens/seller/SellerOverviewScreen";
import { SellerProperties } from "./screens/seller/SellerPropertiesScreen";
import { FAQPage, PrivacyPage, TermsPage } from "./screens/support/SupportScreens";
import { ChatWidget } from "./components/chat/ChatWidget";
import "./styles/index.css";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<PublicLayout />}>
          <Route index element={<HomePage />} />
          <Route path="properties" element={<PropertiesPage />} />
          <Route path="properties/:id" element={<ProtectedRoute><PropertyDetailPage /></ProtectedRoute>} />
          <Route path="saved" element={<ProtectedRoute><SavedPage /></ProtectedRoute>} />
          <Route path="account" element={<ProtectedRoute><AccountPage /></ProtectedRoute>} />
          <Route path="messages" element={<ProtectedRoute><SimplePage type="messages" /></ProtectedRoute>} />
          <Route path="faq" element={<FAQPage />} />
          <Route path="terms" element={<TermsPage />} />
          <Route path="privacy" element={<PrivacyPage />} />
          <Route path="forgot-password" element={<SimplePage type="forgot" />} />
        </Route>

        <Route path="login" element={<AuthPage mode="login" />} />
        <Route path="register" element={<AuthPage mode="register" />} />

        <Route path="seller" element={<ProtectedRoute><SellerLayout /></ProtectedRoute>}>
          <Route path="overview" element={<SellerOverview />} />
          <Route path="properties" element={<SellerProperties />} />
          <Route path="post" element={<PostProperty />} />
          <Route path="customers" element={<SimplePage type="customers" />} />
          <Route index element={<Navigate to="overview" replace />} />
        </Route>

        <Route path="*" element={<NotFound />} />
      </Routes>
      <ChatWidget />
    </BrowserRouter>
  );
}
