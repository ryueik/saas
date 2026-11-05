import { AuthForm } from "@/components/modules/auth-form";
import { signUp } from "../actions";

export default function SignupPage() {
  return <AuthForm mode="signup" action={signUp} />;
}
