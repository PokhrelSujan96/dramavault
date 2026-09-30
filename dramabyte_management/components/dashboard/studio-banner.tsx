export function StudioBanner({ onCreate }: { onCreate: () => void }) {
  return <section className="studio-banner">
    <div className="studio-emblem">DRAMABYTE<br />STUDIO</div>
    <div className="studio-banner-copy">
      <h1>Create with Drama Studio <span>FLAGSHIP</span></h1>
      <p>Turn your story into a narrated, cinematic drama with expressive voices, accurate captions, and captivating visuals.</p>
    </div>
    <button onClick={onCreate} type="button">Create drama video</button>
  </section>;
}
