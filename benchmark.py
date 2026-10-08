import threading
import collections

def run_once(use_lock=False):
    counter = 0
    lock = threading.Lock()

    def worker():
        nonlocal counter
        for _ in range(10_000):
            if use_lock:
                with lock:
                    counter += 1
            else:
                counter += 1

    threads = [threading.Thread(target=worker) for _ in range(10)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return counter

def main():
    runs = 100
    race_results = [run_once(use_lock=False) for _ in range(runs)]
    locked_results = [run_once(use_lock=True) for _ in range(runs)]

    print("Race condition results:")
    print(f"  min={min(race_results)}, max={max(race_results)}")
    print(f"  exactly 100000: {race_results.count(100000)}/{runs}")
    print("  most common:", collections.Counter(race_results).most_common(5))

    print("\nLocked results:")
    print(f"  min={min(locked_results)}, max={max(locked_results)}")
    print(f"  exactly 100000: {locked_results.count(100000)}/{runs}")

if __name__ == "__main__":
    main()
