"use client";

import Link from "next/link";
import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { AuthFormState } from "@/types/auth";

interface AuthFormProps {
  mode: "login" | "signup";
  action: (prev: AuthFormState, formData: FormData) => Promise<AuthFormState>;
  next?: string;
}

export function AuthForm({ mode, action, next }: AuthFormProps) {
  const [state, formAction, pending] = useActionState(action, {});
  const isLogin = mode === "login";

  return (
    <form action={formAction} className="flex w-full max-w-sm flex-col gap-4">
      <h1 className="text-2xl font-semibold">{isLogin ? "Entrar" : "Criar conta"}</h1>
      {next ? <input type="hidden" name="next" value={next} /> : null}
      {!isLogin ? (
        <>
          <Input id="fullName" name="fullName" label="Seu nome" autoComplete="name" maxLength={120} required />
          <Input
            id="organizationName"
            name="organizationName"
            label="Agência ou empresa"
            autoComplete="organization"
            maxLength={120}
            required
          />
        </>
      ) : null}
      <Input id="email" name="email" type="email" label="E-mail" autoComplete="email" required />
      <Input
        id="password"
        name="password"
        type="password"
        label="Senha"
        autoComplete={isLogin ? "current-password" : "new-password"}
        minLength={8}
        required
      />
      {state.error ? (
        <p role="alert" className="text-sm text-red-600">{state.error}</p>
      ) : null}
      {state.message ? <p className="text-sm text-green-700">{state.message}</p> : null}
      <Button type="submit" disabled={pending}>
        {pending ? "Aguarde..." : isLogin ? "Entrar" : "Cadastrar"}
      </Button>
      <p className="text-sm text-zinc-600 dark:text-zinc-400">
        {isLogin ? "Ainda não tem conta? " : "Já tem conta? "}
        <Link className="underline" href={isLogin ? "/signup" : "/login"}>
          {isLogin ? "Cadastre-se" : "Entrar"}
        </Link>
      </p>
    </form>
  );
}
