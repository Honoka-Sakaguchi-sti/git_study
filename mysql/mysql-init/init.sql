-- データベースが存在しなければ作成し、使用する
CREATE DATABASE IF NOT EXISTS my_upsert_db;
USE my_upsert_db;

-- -----------------------------------------------------
-- Table `products` (商品テーブル - 差分更新テスト用)
-- product_code に UNIQUE 制約があるのがポイント
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS project (
    project_id INT AUTO_INCREMENT PRIMARY KEY, -- テーブル管理用ID
    project_br_num VARCHAR(30) NOT NULL,         -- PJコード枝番 (UNIQUE制約はproject_codeとvalid_fromの複合で)
    project_name VARCHAR(100) NOT NULL,        -- PJ名称
    project_contract_form VARCHAR(30),         -- PJ契約形態
    project_sched_self DATE,                 -- 予定期間(自)
    project_sched_to DATE,                   -- 予定期間(至)
    project_type_name VARCHAR(30),             -- PJタイプ名称
    project_classification VARCHAR(30),        -- PJ分類
    project_estimate_num VARCHAR(30),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
