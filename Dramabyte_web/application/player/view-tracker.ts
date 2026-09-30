export function createViewTracker(send: (event: string) => Promise<boolean>, identifier: () => string) {
  let watch = { event: identifier(), watched: 0, last: 0, sent: false, pending: false, attempts: 0, retryAt: 0 };
  const tick = (now: number, playing: boolean) => {
    if (!playing) { watch.last = 0; return; }
    if (watch.last) watch.watched += Math.min(Math.max(now - watch.last, 0), 750);
    watch.last = now;
    if (watch.watched < 2000 || watch.sent || watch.pending || watch.attempts >= 3 || now < watch.retryAt) return;
    const current = watch;
    current.pending = true; current.attempts++;
    void send(current.event).then((success) => { current.sent = success; }).catch(() => {}).finally(() => { current.pending = false; current.retryAt = now + 5000; });
  };
  const reset = () => { watch = { event: identifier(), watched: 0, last: 0, sent: false, pending: false, attempts: 0, retryAt: 0 }; };
  return { tick, reset };
}
