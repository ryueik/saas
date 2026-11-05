"use server";

import { redirect } from "next/navigation";
import { z } from "zod";
import { publicEnv } from "@/lib/env";
import { createClient } from "@/lib/supabase/server";
import type { AuthFormState } from "@/types/auth";
import { safeRedirectPath } from "@/utils/safe-redirect";

const credentialsSchema = z.object({
  email: z.email("E-mail inválido").max(254),
  password: z.string().min(8, "A senha precisa ter pelo menos 8 caracteres").max(72),
});

export async function signIn(_prev: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const parsed = credentialsSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  // Generic message: do not reveal whether the e-mail exists.
  if (error) return { error: "E-mail ou senha incorretos." };

  redirect(safeRedirectPath(formData.get("next")));
}

const signUpSchema = credentialsSchema.extend({
  fullName: z.string().trim().min(1, "Informe seu nome").max(120),
  organizationName: z.string().trim().min(1, "Informe o nome da agência/empresa").max(120),
});

export async function signUp(_prev: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const parsed = signUpSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
    fullName: formData.get("fullName"),
    organizationName: formData.get("organizationName"),
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const { email, password, fullName, organizationName } = parsed.data;
  const supabase = await createClient();
  // The on_auth_user_created trigger reads this metadata to create the
  // organization (user as owner), the profile and a pending subscription.
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${publicEnv.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      data: { full_name: fullName, organization_name: organizationName },
    },
  });
  if (error) return { error: "Não foi possível criar a conta. Tente novamente." };

  return { message: "Conta criada! Confira seu e-mail para confirmar o cadastro." };
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
