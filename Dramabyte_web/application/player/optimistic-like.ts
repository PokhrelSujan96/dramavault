export function createOptimisticLike(initial: { liked: boolean; likes: number }, save: (liked: boolean) => Promise<void>, onChange: (state: { liked: boolean; likes: number; error: string | null }) => void) {
  let confirmed = initial.liked;
  let desired = initial.liked;
  let syncing = false;
  let disposed = false;
  const emit = (error: string | null = null) => {
    if (!disposed) onChange({ liked: desired, likes: Math.max(0, initial.likes + Number(desired) - Number(initial.liked)), error });
  };
  const sync = async () => {
    if (syncing) return;
    syncing = true;
    try {
      while (confirmed !== desired) {
        const target = desired;
        try { await save(target); confirmed = target; }
        catch (failure) {
          desired = confirmed;
          emit(failure instanceof Error ? failure.message : "Couldn’t update your like. Please try again.");
          break;
        }
      }
    } finally { syncing = false; }
  };
  return {
    toggle: () => { if (disposed) return; desired = !desired; emit(); void sync(); },
    dispose: () => { disposed = true; },
    activate: () => { disposed = false; },
  };
}
