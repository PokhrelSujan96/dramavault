"use client";

export default function WatchError({ reset }: { reset: () => void }) {
  return <main className="container empty"><h1>Couldn’t load this episode</h1><p>Please try again in a moment.</p><button className="button button-dark" onClick={reset}>Try again</button></main>;
}
