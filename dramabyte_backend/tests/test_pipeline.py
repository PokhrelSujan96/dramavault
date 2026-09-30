from app.application.pipeline import PIPELINE, PipelinePlan
from app.domain.models import PipelineStage


def test_pipeline_weights_total_one_hundred() -> None:
    assert sum(stage.weight for stage in PIPELINE) == 100


def test_pipeline_can_resume_from_stage() -> None:
    stages = PipelinePlan().stages_from(PipelineStage.video)
    assert stages[0].stage == PipelineStage.video
    assert stages[-1].stage == PipelineStage.publish
