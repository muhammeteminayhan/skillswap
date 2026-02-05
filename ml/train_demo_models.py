import json
from pathlib import Path
import numpy as np
from sklearn.linear_model import LinearRegression, LogisticRegression

rng = np.random.default_rng(42)

# Fairness/value model training data
n = 400
hours = rng.uniform(0.5, 8.0, size=n)
difficulty = rng.integers(1, 6, size=n)
risk = rng.integers(1, 6, size=n)
noise = rng.normal(0, 0.7, size=n)
value_target = (hours * (1.35 * difficulty + 1.1 * risk) + noise).clip(1)
X_value = np.column_stack([hours, difficulty, risk])
value_model = LinearRegression().fit(X_value, value_target)

# Churn model data
m = 500
days_inactive = rng.integers(0, 45, size=m)
open_requests = rng.integers(0, 8, size=m)
unread_messages = rng.integers(0, 12, size=m)
trust_score = rng.integers(40, 100, size=m)
logit = (
    -1.6
    + 0.08 * days_inactive
    + 0.22 * open_requests
    + 0.11 * unread_messages
    - 0.04 * trust_score
)
prob = 1 / (1 + np.exp(-logit))
y_churn = rng.binomial(1, prob)
X_churn = np.column_stack([days_inactive, open_requests, unread_messages, trust_score])
churn_model = LogisticRegression(max_iter=800).fit(X_churn, y_churn)

# Trust model training data
k = 500
completion_rate = rng.uniform(0.4, 1.0, size=k)
response_rate = rng.uniform(0.3, 1.0, size=k)
review_score = rng.uniform(2.0, 5.0, size=k)
cancel_rate = rng.uniform(0.0, 0.5, size=k)
trust_target = (
    20
    + 45 * completion_rate
    + 25 * response_rate
    + 8 * review_score
    - 30 * cancel_rate
    + rng.normal(0, 4, size=k)
).clip(20, 99)
X_trust = np.column_stack([completion_rate, response_rate, review_score, cancel_rate])
trust_model = LinearRegression().fit(X_trust, trust_target)

semantic_categories = {
    "Elektrik": ["elektrik", "priz", "avize", "sigorta", "kablo", "aydınlatma"],
    "Tesisat": ["tesisat", "musluk", "su", "kaçağı", "boru", "lavabo"],
    "Doğalgaz": ["doğalgaz", "kombi", "petek", "kalorifer", "gaz"],
    "PC": ["pc", "bilgisayar", "laptop", "format", "yazıcı", "modem"],
    "Boya": ["boya", "duvar", "alçı", "fırça", "iç cephe"],
    "Mobilya": ["mobilya", "dolap", "kapı", "menteşe", "montaj", "raf"],
}

model = {
    "version": "2026-02-05",
    "semantic": {
        "weights": {
            "wantOverlap": 0.50,
            "offerOverlap": 0.30,
            "trust": 0.15,
            "reciprocity": 0.05,
        },
        "categories": semantic_categories,
    },
    "fairnessModel": {
        "intercept": float(value_model.intercept_),
        "hours": float(value_model.coef_[0]),
        "difficulty": float(value_model.coef_[1]),
        "risk": float(value_model.coef_[2]),
        "tokenRate": 10,
    },
    "churnModel": {
        "intercept": float(churn_model.intercept_[0]),
        "daysInactive": float(churn_model.coef_[0][0]),
        "openRequests": float(churn_model.coef_[0][1]),
        "unreadMessages": float(churn_model.coef_[0][2]),
        "trustScore": float(churn_model.coef_[0][3]),
    },
    "trustModel": {
        "intercept": float(trust_model.intercept_),
        "completionRate": float(trust_model.coef_[0]),
        "responseRate": float(trust_model.coef_[1]),
        "reviewScore": float(trust_model.coef_[2]),
        "cancelRate": float(trust_model.coef_[3]),
    },
}

repo_root = Path(__file__).resolve().parent.parent
output = repo_root / "backend" / "src" / "main" / "resources" / "ml" / "skillswap-model.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(model, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"wrote {output}")
