import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os
import time

# --- データベース接続設定 ---
DATABASE_HOST = os.getenv("DATABASE_HOST", "db")
DATABASE_NAME = os.getenv("DATABASE_NAME", "my_upsert_db") # init.sqlと合わせる
DATABASE_USER = os.getenv("DATABASE_USER", "user")
DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD", "pass")
DATABASE_PORT = os.getenv("DATABASE_PORT", "3306")

SQLALCHEMY_DATABASE_URL = (
    f"mysql+pymysql://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
)

# データベース接続のリトライロジック (コンテナ起動タイミング問題対策)
def get_db_engine(max_retries=10, delay_seconds=5):
    for i in range(max_retries):
        try:
            engine = create_engine(SQLALCHEMY_DATABASE_URL, echo=True)
            with engine.connect() as connection:
                connection.execute(text("SELECT 1")) # 接続テスト
            print("データベース接続に成功しました！")
            return engine
        except Exception as e:
            print(f"データベース接続エラー: {e}")
            if i < max_retries - 1:
                print(f"{delay_seconds}秒待機してリトライします... (試行 {i+1}/{max_retries})")
                time.sleep(delay_seconds)
            else:
                print("最大リトライ回数に達しました。接続できません。")
                raise

engine = get_db_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# --- 差分更新ロジック ---
def upsert_products_from_csv(csv_file_path: str):
    """
    CSVファイルから商品データを読み込み、INSERT ... ON DUPLICATE KEY UPDATE で差分更新する。
    """
    """
    CSVファイルからプロジェクトデータを読み込み、SCD Type 2ロジックでprojectsテーブルを更新する。
    CSVの日本語ヘッダーをDBのカラム名（英語）に正確にマッピングする。
    is_flag カラムはCSVにない前提。
    """
    today = date.today()
    yesterday = today - pd.Timedelta(days=1)

    db = SessionLocal()
    try:
         # (1) CSVファイルを読み込む
        print(f"\n--- CSVファイル {csv_file_path} を読み込み中 ---")
        new_projects_df = pd.read_csv(csv_file_path)
        print(f"読み込み完了。新規データ件数 (CSV): {len(new_projects_df)}")

        # ★★★ CSVの日本語ヘッダーをDBのカラム名（英語）に正確にマッピング ★★★
        new_projects_df.rename(columns={
            'ＰＪコード枝番': 'project_br_num', 
            'ＰＪ名称': 'project_name',
            'ＰＪ契約形態': 'project_contract_form',
            '予定期間(自)': 'project_sched_self',
            '予定期間(至)': 'project_sched_to',
            'ＰＪタイプ名称': 'project_type_name',
            'ＰＪ分類': 'project_classification',
            '実行予算見積番号': 'project_estimate_num',
            # is_flag はCSVにないため、ここでのマッピングは不要
        }, inplace=True)
        # ★★★ ここまで修正 ★★★

        # (2) 各行をループし、INSERT ... ON DUPLICATE KEY UPDATE を実行
        print("--- データベース更新中 (Upsert) ---")
        insert_update_query = text("""
            INSERT INTO products (
                project_id, project_br_num, project_name, project_contract_form, project_sched_self,
                project_sched_to, project_type_name, project_classification,
                project_estimate_num, created_at, updated_at
            ) VALUES (
                :project_br_num, :project_name, :project_contract_form, :project_sched_self, :project_sched_to,
                :project_type_name, :project_classification, :project_estimate_num, :created_at, :updated_at
            )
            ON DUPLICATE KEY UPDATE
                project_name = VALUES(project_name),
                project_contract_form = VALUES(project_contract_form),
                project_sched_self = VALUES(project_sched_self),
                project_sched_to = VALUES(project_sched_to),
                project_type_name = VALUES(project_type_name),
                project_classification = VALUES(project_classification),
                project_estimate_num = VALUES(project_estimate_num),
                updated_at = NOW()
        """)
        
        for index, row in products_df.iterrows():
            record = row.to_dict()
            # created_at は初回挿入時のみなので、ここではNOW()を渡し、ON DUPLICATE KEY UPDATEでは更新しない
            # updated_at は毎回NOW()で更新
            record['created_at'] = datetime.now()
            record['updated_at'] = datetime.now()
            db.execute(insert_update_query, record)
            
        db.commit()
        print("--- データベース更新が完了しました！ ---")

    except Exception as e:
        db.rollback()
        print(f"エラーが発生しました。トランザクションをロールバックしました: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("使用方法: python import_products.py <csv_file_path>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    upsert_products_from_csv(csv_file)
