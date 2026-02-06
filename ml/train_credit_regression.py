import argparse
from pathlib import Path
import pandas as pd
import numpy as np
from datetime import datetime


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv', default='data/synthetic_training_data_520.csv')
    parser.add_argument('--out-dir', default='data')
    args = parser.parse_args()

    csv_path = Path(args.csv)
    if not csv_path.exists():
        raise SystemExit(f"CSV not found: {csv_path}")

    df = pd.read_csv(csv_path)

    required = ['hours', 'difficulty', 'risk', 'scope', 'trustScore', 'creditScore', 'category']
    for col in required:
        if col not in df.columns:
            raise SystemExit(f"Missing column: {col}")

    X = df[['hours', 'difficulty', 'risk', 'scope', 'trustScore']].to_numpy(dtype=float)
    y = df['creditScore'].to_numpy(dtype=float)
    X = np.column_stack([np.ones(len(X)), X])

    coef, *_ = np.linalg.lstsq(X, y, rcond=None)
    intercept, w_hours, w_difficulty, w_risk, w_scope, w_trust = coef.tolist()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    dataset_name = csv_path.name
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    model_sql = f"""INSERT INTO credit_regression_models (intercept, hours, difficulty, risk, scope, trust, min_credit, max_credit, dataset_name, trained_at)\nVALUES ({intercept:.6f}, {w_hours:.6f}, {w_difficulty:.6f}, {w_risk:.6f}, {w_scope:.6f}, {w_trust:.6f}, 50, 150, '{dataset_name}', '{now}');\n"""
    (out_dir / 'credit_regression_model.sql').write_text(model_sql, encoding='utf-8')

    profiles = (
        df.groupby('category')[['hours', 'difficulty', 'risk', 'scope']]
        .mean()
        .reset_index()
    )

    profile_lines = [
        'INSERT INTO credit_profiles (category, hours, difficulty, risk, scope) VALUES'
    ]
    values = []
    for _, row in profiles.iterrows():
        values.append(
            f"('{row['category']}', {row['hours']:.2f}, {int(round(row['difficulty']))}, {int(round(row['risk']))}, {row['scope']:.2f})"
        )
    profile_lines.append(',\n'.join(values) + ';\n')
    (out_dir / 'credit_profiles_seed.sql').write_text('\n'.join(profile_lines), encoding='utf-8')

    print('Regression coefficients:')
    print('intercept', intercept)
    print('hours', w_hours)
    print('difficulty', w_difficulty)
    print('risk', w_risk)
    print('scope', w_scope)
    print('trust', w_trust)
    print('wrote', out_dir / 'credit_regression_model.sql')
    print('wrote', out_dir / 'credit_profiles_seed.sql')


if __name__ == '__main__':
    main()
