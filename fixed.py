import threading

counter = 0
lock = threading.Lock()

def worker():
    global counter
    for _ in range(10_000):
        with lock:
            counter += 1

threads = [threading.Thread(target=worker) for _ in range(10)]
for t in threads:
    t.start()
for t in threads:
    t.join()

print(f"Final counter with lock: {counter}")
