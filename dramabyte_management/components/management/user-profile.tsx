import { useState } from "react";
import { useCachedQuery } from "@/hooks/use-cached-query";
import { writeManagement } from "@/lib/optimistic-management";
import type { CoinTransaction, UserProfile } from "./management-types";

type Props = { user: UserProfile; onClose: () => void; onChanged: () => Promise<void> };
export function UserProfilePanel({ user, onClose }: Props) {
  const query = useCachedQuery<{ profile: UserProfile; transactions: CoinTransaction[] }>(`/admin/users/${user.id}`);
  const [draft, setProfile] = useState(user);
  const profile = { ...(query.data?.profile ?? user), display_name: draft.display_name, country: draft.country, language: draft.language };
  const transactions = query.data?.transactions ?? [];
  const [amount, setAmount] = useState(0);
  const [reason, setReason] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [requestId, setRequestId] = useState<string>();
  async function act(path: string, method: string, body?: unknown) {
    setBusy(true); setError("");
    try { await writeManagement(`/admin/users/${user.id}${path}`, method, body); return true; }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Action failed"); return false; }
    finally { setBusy(false); }
  }
  return <div className="management-modal" role="dialog" aria-modal="true" aria-label="User profile">
    <section className="profile-panel"><header><div><h2>{profile.display_name || "User profile"}</h2><p>{profile.email}</p></div><button onClick={onClose} type="button">Close</button></header>
      {(error || query.error) && <p role="alert" className="dashboard-error">{error || query.error}</p>}
      <div className="profile-facts">{Object.entries(profile).filter(([key]) => !["display_name", "email", "avatar_url"].includes(key)).map(([key, value]) => <div key={key}><span>{key.replaceAll("_", " ")}</span><strong>{String(value ?? "—")}</strong></div>)}</div>
      <form onSubmit={(event) => { event.preventDefault(); void act("", "PATCH", { display_name: profile.display_name, country: profile.country, language: profile.language }); }}>
        <h3>Edit profile</h3><label>Name<input value={profile.display_name} maxLength={160} onChange={(event) => setProfile({ ...profile, display_name: event.target.value })} /></label>
        <label>Country<input value={profile.country ?? ""} onChange={(event) => setProfile({ ...profile, country: event.target.value })} /></label>
        <label>Language<input required minLength={2} maxLength={12} value={profile.language} onChange={(event) => setProfile({ ...profile, language: event.target.value })} /></label><button disabled={busy}>Save profile</button>
      </form>
      <form onSubmit={(event) => { event.preventDefault(); const id = requestId ?? crypto.randomUUID(); setRequestId(id); void act("/coins", "POST", { amount, reason, request_id: id }).then((success) => { if (success) { setAmount(0); setReason(""); setRequestId(undefined); } }); }}>
        <h3>Adjust coins</h3><p>Positive amounts give coins. Negative amounts deduct coins.</p><label>Amount<input type="number" required min={-1000000} max={1000000} value={amount} onChange={(event) => { setAmount(Number(event.target.value)); setRequestId(undefined); }} /></label><label>Reason<input required minLength={3} maxLength={500} value={reason} onChange={(event) => { setReason(event.target.value); setRequestId(undefined); }} /></label><button disabled={busy || !amount || !!profile.deleted_at}>Apply adjustment</button>
      </form>
      <div className="management-actions"><button disabled={busy || !!profile.deleted_at} onClick={() => void act("", "PATCH", { is_suspended: !profile.is_suspended })}>{profile.is_suspended ? "Unsuspend" : "Suspend"}</button><button disabled={busy} onClick={() => { if (profile.deleted_at) void act("/restore", "POST"); else if (window.confirm("Remove this account? Access will be blocked. You can restore it later.")) void act("", "DELETE"); }}>{profile.deleted_at ? "Restore account" : "Remove account"}</button></div>
      <h3>Coin history</h3><table><thead><tr><th>Date</th><th>Amount</th><th>Reason</th><th>Balance</th></tr></thead><tbody>{transactions.map((item) => <tr key={item.id}><td>{new Date(item.created_at).toLocaleString()}</td><td>{item.amount}</td><td>{item.reason}</td><td>{item.balance_after}</td></tr>)}</tbody></table>{!transactions.length && <p>No coin transactions yet.</p>}
    </section>
  </div>;
}
