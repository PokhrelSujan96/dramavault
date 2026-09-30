from dataclasses import dataclass

from app.domain.models import PipelineStage


@dataclass(frozen=True, slots=True)
class StageDefinition:
    stage: PipelineStage
    queue: str
    weight: int
    retry_limit: int


PIPELINE = (
    StageDefinition(PipelineStage.script, "ai", 8, 2),
    StageDefinition(PipelineStage.storyboard, "ai", 7, 2),
    StageDefinition(PipelineStage.images, "gpu", 20, 3),
    StageDefinition(PipelineStage.video, "gpu", 35, 3),
    StageDefinition(PipelineStage.voice, "audio", 10, 3),
    StageDefinition(PipelineStage.subtitles, "audio", 7, 2),
    StageDefinition(PipelineStage.render, "render", 10, 2),
    StageDefinition(PipelineStage.publish, "default", 3, 3),
)


class PipelinePlan:
    def stages_from(self, start: PipelineStage | None) -> tuple[StageDefinition, ...]:
        if start is None:
            return PIPELINE
        index = next(i for i, item in enumerate(PIPELINE) if item.stage == start)
        return PIPELINE[index:]

    def progress_after(self, stage: PipelineStage) -> int:
        completed = 0
        for definition in PIPELINE:
            completed += definition.weight
            if definition.stage == stage:
                return completed
        return 0

    def next_stage(self, stage: PipelineStage) -> PipelineStage | None:
        index = next(i for i, item in enumerate(PIPELINE) if item.stage == stage)
        return PIPELINE[index + 1].stage if index + 1 < len(PIPELINE) else None
