# Local reranker models

Official model: `Qwen/Qwen3-Reranker-0.6B` (Apache-2.0).

From `real-estate-ai/`:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\hf.exe download Qwen/Qwen3-Reranker-0.6B --revision e61197ed45024b0ed8a2d74b80b4d909f1255473 --local-dir ./models/Qwen3-Reranker-0.6B
```

The Hugging Face CLI downloads the pinned official revision directly to
`models/Qwen3-Reranker-0.6B/`. The existing `download-manifest.json` from the first
download is retained with the model. Keep the pinned revision to reproduce a deployment. Model weights and download caches are ignored
by Git. Do not commit or upload them with application source.

Serving uses **vLLM pooling**, the official Qwen3 yes/no classifier overrides and
the checked-in chat template. It does not use a generic text-generation endpoint.
The 6 GB development GPU profile uses FP16 without quantization,
one sequence and 2048 tokens. Fit, performance and Vietnamese retrieval quality
must be measured on the actual machine; the 0.6B weights are substantially smaller, but memory usage still needs a live smoke test. See `docs/SETUP_FULL_STACK.md` for the WSL2/Docker commands.
