"use client";

import { FormEvent, useState } from "react";
import { ArrowRight, LockKeyhole, Sparkles } from "lucide-react";
import { apiRequest } from "@/lib/api-client";

type Props = {
  onSuccess: () => Promise<void>;
};

export function LoginScreen({ onSuccess }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError("");
    try {
      await apiRequest("/auth/sign-in", {
        method: "POST",
        body: { email, password },
      });
      await onSuccess();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Unable to sign in");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="login-page">
      <section className="login-intro">
        <div className="login-brand"><span>D</span> DRAMABYTE</div>
        <div>
          <p className="eyebrow">Production intelligence</p>
          <h1>Stories in.<br />Cinema out.</h1>
          <p>Plan, generate, review, and publish every short drama from one secure workspace.</p>
        </div>
        <div className="login-flow">
          <span><Sparkles size={16} /> Script</span>
          <i />
          <span>Scenes</span>
          <i />
          <span>Master</span>
        </div>
      </section>
      <section className="login-panel">
        <form className="login-card" onSubmit={submit}>
          <span className="login-lock"><LockKeyhole size={19} /></span>
          <h2>Welcome back</h2>
          <p>Sign in with your Supabase administrator account.</p>
          <label>Email<input autoComplete="email" onChange={(event) => setEmail(event.target.value)} required type="email" value={email} /></label>
          <label>Password<input autoComplete="current-password" minLength={8} onChange={(event) => setPassword(event.target.value)} required type="password" value={password} /></label>
          {error ? <p className="form-error">{error}</p> : null}
          <button disabled={submitting} type="submit">
            {submitting ? "Signing in..." : "Enter workspace"}<ArrowRight size={17} />
          </button>
        </form>
      </section>
    </main>
  );
}
