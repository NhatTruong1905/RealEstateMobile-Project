"""Public answer text normalization."""
import re

def clean_output_text(text: str) -> str:
    if not text:
        return ""
    cleaned = text.replace("*", "")
    cleaned = re.sub(r'\(\s*Ward\s*ID:\s*\d+\s*,\s*District\s*ID:\s*\d+\s*\)', '', cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r'\(\s*(?:Ward|District)\s*ID:\s*\d+\s*\)', '', cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r'\b(?:Ward|District|wardId|districtId)\s*ID?\s*[:=]?\s*\d+\b', '', cleaned, flags=re.IGNORECASE)
    return cleaned
