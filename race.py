import threading

counter = 0

def worker():
    global counter
    for _ in range(10_000):
        counter += 1   # read, add, write — not atomic

threads = [threading.Thread(target=worker) for _ in range(10)]
for t in threads:
    t.start()
for t in threads:
    t.join()

print(f"Final counter: {counter}")
