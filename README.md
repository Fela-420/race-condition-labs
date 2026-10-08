# Race Condition Lab 1: Basic Interleaving

This repo demonstrates a basic race condition using a shared counter in Python.

## Objective
See nondeterminism caused by non-atomic read-modify-write operations.

## Setup
- Python 3.8+
- (Optional) matplotlib for histogram

## Files
- `race.py` — vulnerable counter with 10 threads × 10,000 increments.
- `fixed.py` — same counter protected by `threading.Lock`.
- `benchmark.py` — runs each version 100 times and prints statistics.

## How to run
```bash
python race.py
python fixed.py
python benchmark.py
