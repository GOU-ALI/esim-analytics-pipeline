import csv
import random
import datetime
import uuid
import os

# Configuration
NUM_CUSTOMERS = 1000
NUM_ORDERS = 1500
START_DATE = datetime.datetime(2025, 1, 1)
END_DATE = datetime.datetime(2025, 12, 31)

DEVICES = [
    ("iPhone 15 Pro", 0.3),
    ("iPhone 14", 0.2),
    ("Pixel 8", 0.15),
    ("Galaxy S24", 0.2),
    ("iPad Pro", 0.05),
    ("Other", 0.1)
]

COUNTRIES = ["FR", "US", "UK", "DE", "JP"]
STATUSES = ["SUCCESS", "FAILED"]
FAILURE_REASONS = ["TIMEOUT", "USER_CANCELLED", "SMDP_ERROR", "NETWORK_ERROR"]

# Ensure output directory exists and use absolute path
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

def random_date(start, end):
    return start + datetime.timedelta(
        seconds=random.randint(0, int((end - start).total_seconds()))
    )

def weighted_choice(choices):
    total = sum(w for c, w in choices)
    r = random.uniform(0, total)
    upto = 0
    for c, w in choices:
        if r <= upto + w:
            return c
        upto += w
    return choices[0][0]

print(f"Generating eSIM Data in {OUTPUT_DIR}...")

customers = [str(uuid.uuid4()) for _ in range(NUM_CUSTOMERS)]
orders = []

# Generate Orders
with open(os.path.join(OUTPUT_DIR, 'esim_orders.csv'), 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(["order_id", "customer_id", "device_model", "country", "order_timestamp"])
    
    for _ in range(NUM_ORDERS):
        o_id = str(uuid.uuid4())
        c_id = random.choice(customers)
        model = weighted_choice(DEVICES)
        country = random.choice(COUNTRIES)
        ts = random_date(START_DATE, END_DATE)
        
        orders.append({
            "order_id": o_id,
            "customer_id": c_id,
            "device_model": model,
            "timestamp": ts
        })
        writer.writerow([o_id, c_id, model, country, ts.isoformat()])

print(f"Generated {NUM_ORDERS} orders.")

# Generate Activations
with open(os.path.join(OUTPUT_DIR, 'esim_activations.csv'), 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(["order_id", "iccid", "smdp_address", "status", "failure_reason", "provisioning_duration_sec", "activation_timestamp"])
    
    for order in orders:
        # Simulate 90% success rate
        is_success = random.random() < 0.90
        status = "SUCCESS" if is_success else "FAILED"
        
        # Provisioning time: random between 5s and 120s
        duration = random.randint(5, 120)
        
        # Reason is null if success
        reason = ""
        if not is_success:
            reason = random.choice(FAILURE_REASONS)
            duration = random.randint(120, 300) # Failures often take longer (timeouts)

        # Activation happens shortly after order
        act_ts = order["timestamp"] + datetime.timedelta(seconds=random.randint(10, 600))
        
        # ICCID (Integrated Circuit Card ID) - fake
        iccid = f"893301{random.randint(1000000000000, 9999999999999)}"
        smdp = "rsp.esim.google.com"
        
        writer.writerow([order["order_id"], iccid, smdp, status, reason, duration, act_ts.isoformat()])

print(f"Generated activations for orders.")

# Generate Data Usage
with open(os.path.join(OUTPUT_DIR, 'esim_usage.csv'), 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "session_id", "bytes_consumed", "session_duration_min", "timestamp"])
    
    # Generate 5000 usage sessions
    for _ in range(5000):
        c_id = random.choice(customers)
        ts = random_date(START_DATE, END_DATE)
        
        # Random usage
        mb_used = random.expovariate(1/500) # avg 500MB
        bytes_used = int(mb_used * 1024 * 1024)
        duration_min = random.randint(1, 120)
        
        writer.writerow([c_id, str(uuid.uuid4()), bytes_used, duration_min, ts.isoformat()])

print("Generated usage logs.")
print("Done!")
