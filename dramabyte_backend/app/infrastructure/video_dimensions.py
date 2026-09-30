
def video_dimensions(aspect: str) -> tuple[int, int]:
    dimensions = {
        "9:16": (1080, 1920),
        "16:9": (1920, 1080),
        "1:1": (1080, 1080),
    }
    try:
        return dimensions[aspect]
    except KeyError as error:
        raise ValueError("Unsupported export aspect ratio") from error
