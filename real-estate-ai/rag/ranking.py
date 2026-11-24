import re
from collections import Counter
from math import log

from rag.criteria import normalize


def tokens(text):
    return re.findall(r"[a-z0-9]+", normalize(text))


def fuse_lexical_candidates(query, documents):
    """Fuse dense order with a local BM25-style score over hydrated candidates."""
    terms = set(tokens(query))
    if not terms or len(documents) < 2:
        return documents
    counts = [Counter(tokens(doc.page_content)) for doc in documents]
    lengths = [sum(count.values()) for count in counts]
    average = max(1, sum(lengths) / len(lengths))
    frequencies = {term: sum(term in count for count in counts) for term in terms}
    idf = {term: log(1 + (len(counts) - frequency + 0.5) / (frequency + 0.5))
           for term, frequency in frequencies.items() if frequency}
    scores = [
        sum(weight * 2.2 * count[term] / (count[term] + 1.2 * (0.25 + 0.75 * length / average))
            for term, weight in idf.items() if count[term])
        for count, length in zip(counts, lengths)
    ]
    lexical = sorted((i for i, score in enumerate(scores) if score > 0),
                     key=lambda i: scores[i], reverse=True)
    if not lexical:
        return documents
    ranks = {index: rank for rank, index in enumerate(lexical)}
    ordering = sorted(range(len(documents)), key=lambda i:
                      1 / (10 + i) + 1 / (10 + ranks.get(i, len(lexical) + i)), reverse=True)
    return [documents[i] for i in ordering]
