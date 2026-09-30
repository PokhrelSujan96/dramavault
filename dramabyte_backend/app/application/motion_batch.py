from collections.abc import Callable
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from pathlib import Path
from typing import Any

from app.infrastructure.hybrid_assets import HybridAssets


def generate_motion(
    shots: list[dict[str, Any]],
    assets: HybridAssets,
    run: dict[str, Any],
    aspect: str,
    root: Path,
    progress: Callable[[int], None],
) -> None:
    motion = [shot for shot in shots if shot["kind"] == "motion"]
    remaining = iter(motion)
    with ThreadPoolExecutor(max_workers=2) as pool:
        pending = set()

        def enqueue() -> None:
            shot = next(remaining, None)
            if shot is not None:
                assets.lease.ensure()
                pending.add(pool.submit(assets.video, shot, run, aspect, root))

        enqueue()
        enqueue()
        completed = 0
        while pending:
            done, pending = wait(pending, return_when=FIRST_COMPLETED)
            for future in done:
                future.result()
            completed += len(done)
            progress(completed)
            for _ in done:
                enqueue()
