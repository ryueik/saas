import { Suspense } from "react";
import { AuthForm } from "@/components/modules/auth-form";
import { safeRedirectPath } from "@/utils/safe-redirect";
import { signIn } from "../actions";

async function LoginForm({ searchParams }: Pick<PageProps<"/login">, "searchParams">) {
  const { next } = await searchParams;
  return <AuthForm mode="login" action={signIn} next={safeRedirectPath(next)} />;
}

export default function LoginPage({ searchParams }: PageProps<"/login">) {
  return (
    <Suspense fallback={<AuthForm mode="login" action={signIn} />}>
      <LoginForm searchParams={searchParams} />
    </Suspense>
  );
}
