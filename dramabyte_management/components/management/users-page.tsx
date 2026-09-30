import { useState } from "react";
import { useManagement } from "@/hooks/use-management";
import type { UserProfile } from "./management-types";
import { UserProfilePanel } from "./user-profile";

export function UsersPage({ query }: { query: string }) {
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<UserProfile>();
  const data = useManagement<UserProfile>(`/admin/users?page=${page}&size=25`);
  const users = data.items.filter((user) => `${user.display_name} ${user.email}`.toLowerCase().includes(query.toLowerCase()));
  return <section className="management-page"><header><div><h1>Users</h1><p>Manage profiles, account access, and coin balances.</p></div><span>{data.total} users</span></header>
    {data.error && <p className="dashboard-error" role="alert">{data.error}</p>}
    <div className="management-card"><table><thead><tr><th>User</th><th>Country</th><th>Coins</th><th>Bonus</th><th>Status</th><th /></tr></thead><tbody>{users.map((user) => <tr key={user.id}><td><strong>{user.display_name || "Unnamed user"}</strong><small>{user.email}</small></td><td>{user.country || "—"}</td><td>{user.coins}</td><td>{user.bonus_coins}</td><td><span className="management-badge">{user.deleted_at ? "Removed" : user.is_suspended ? "Suspended" : "Active"}</span></td><td><button onClick={() => setSelected(user)}>View profile</button></td></tr>)}</tbody></table>{!users.length && <p className="empty-state">{data.busy ? "Loading users…" : "No matching users on this page."}</p>}</div>
    <footer><button disabled={page === 1 || data.busy} onClick={() => setPage(page - 1)}>Previous</button><span>Page {page}</span><button disabled={page * 25 >= data.total || data.busy} onClick={() => setPage(page + 1)}>Next</button></footer>
    {selected && <UserProfilePanel key={selected.id} user={selected} onClose={() => setSelected(undefined)} onChanged={data.reload} />}
  </section>;
}
