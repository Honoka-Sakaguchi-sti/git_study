-- データベースが存在しなければ作成し、使用する
CREATE DATABASE IF NOT EXISTS my_test_db;
USE my_test_db;

-- -- -----------------------------------------------------
-- -- ヒストグラムテーブルの作成
-- -- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS histograms (
--     -- テーブル管理用ID
--     histogram_id INT AUTO_INCREMENT PRIMARY KEY,

--     account_code VARCHAR(30) NOT NULL,
--     account_name VARCHAR(30) NOT NULL,

--     project_branch_number VARCHAR(30) NOT NULL,
--     project_name VARCHAR(100) NOT NULL,
--     project_contract_form VARCHAR(30) NOT NULL,

--     -- 工数単位 (例: 1=円, 2=時間, 3=人月 - INT型の場合)
--     costs_unit INT,

--     -- 対象年
--     histogram_year YEAR,

--     -- 月ごとの合計値 (DECIMAL(5,2)は999.99まで表現可能)
--     histogram_01month DECIMAL(5,2),
--     histogram_02month DECIMAL(5,2),
--     histogram_03month DECIMAL(5,2),
--     histogram_04month DECIMAL(5,2),
--     histogram_05month DECIMAL(5,2),
--     histogram_06month DECIMAL(5,2),
--     histogram_07month DECIMAL(5,2),
--     histogram_08month DECIMAL(5,2),
--     histogram_09month DECIMAL(5,2),
--     histogram_10month DECIMAL(5,2),
--     histogram_11month DECIMAL(5,2),
--     histogram_12month DECIMAL(5,2),

--     -- 作成日時と更新日時 (管理用)
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

--     -- 同じアカウントコード、プロジェクト枝番、年で重複がないことを保証するユニークキー
--     -- これにより、各行が一意のヒストグラム項目と年を表します。
--     UNIQUE KEY uk_histogram_entry (account_code, project_branch_number, histogram_year)
-- );

-- -- -----------------------------------------------------
-- -- サンプルデータの挿入 (オプション)
-- -- -----------------------------------------------------
-- INSERT IGNORE INTO histograms (
--     histogram_id, histogram_ac_code, histogram_pj_br_num, costs_unit, histogram_year,
--     histogram_01month, histogram_02month, histogram_03month, histogram_04month,
--     histogram_05month, histogram_06month, histogram_07month, histogram_08month,
--     histogram_09month, histogram_10month, histogram_11month, histogram_12month
-- ) VALUES
-- (
--     1, 'EMP001', '山田太郎', 'PJ001-01', '新機能開発X',
--     '請負', 1, 2024,
--     100.50, 120.75, 150.00, 0.00,
--     0.00, 0.00, 0.00, 0.00,
--     0.00, 0.00, 0.00, 0.00
-- ),
-- (
--     2, 'EMP002', '佐藤花子', 'PJ002-01', '既存システム改修Y',
--     '準委任', 2, 2024,
--     500.00, 450.00, 0.00, 0.00,
--     0.00, 0.00, 0.00, 0.00,
--     0.00, 0.00, 0.00, 0.00
-- );

-- -----------------------------------------------------
-- Table `projects` (プロジェクトマスター - SCD Type 2適用)
-- ご提示のprojectsテーブル定義に基づき、SCD Type 2のためのカラムを含みます。
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY, -- テーブル管理用ID
    project_br_num VARCHAR(30) NOT NULL,         -- PJコード枝番 (UNIQUE制約はproject_codeとvalid_fromの複合で)
    project_name VARCHAR(100) NOT NULL,        -- PJ名称
    project_contract_form VARCHAR(30),         -- PJ契約形態
    project_sched_self DATE,                 -- 予定期間(自)
    project_sched_to DATE,                   -- 予定期間(至)
    project_type_name VARCHAR(30),             -- PJタイプ名称
    project_classification VARCHAR(30),        -- PJ分類
    project_estimate_num VARCHAR(30)      -- 実行予算見積番号
);

-- -----------------------------------------------------
-- サンプルデータの挿入 (オプション)
-- -----------------------------------------------------
INSERT IGNORE INTO projects (project_id, project_br_num, project_name, project_contract_form, project_sched_self, project_sched_to, project_type_name, project_classification, project_estimate_num, project_valid_from, project_valid_to, project_is_current) VALUES
(101, 'PJ001', '新機能開発X', '請負', '2024-01-01', '2024-06-30', 'システム開発', 'PS', 'EST-001', '2024-01-01', NULL, TRUE),
(102, 'PJ002', '既存システム改修Y', '準委任', '2024-03-15', '2024-12-31', 'システム開発', 'PS', 'EST-002', '2024-03-15', NULL, TRUE);

-- -- -----------------------------------------------------
-- -- Table `users` (ユーザーマスター)
-- -- ご提示のusersテーブル定義に基づきます。
-- -- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS users (
--     user_id INT AUTO_INCREMENT PRIMARY KEY, -- テーブル管理用ID
--     account_code VARCHAR(30) NOT NULL UNIQUE, -- アカウントコード (UNIQUE制約を追加)
--     user_name VARCHAR(30) NOT NULL,         -- メンバー名称
--     user_team VARCHAR(30),                  -- 所属チーム
--     user_type VARCHAR(30),                  -- ユーザー種別
-- );

-- -- -----------------------------------------------------
-- -- サンプルデータの挿入 (オプション)
-- -- -----------------------------------------------------
-- INSERT IGNORE INTO users (user_id, account_code, user_name, user_team, user_type) VALUES
-- (1, 'EMP001', '山田太郎', 'コンテナ', 'LS'),
-- (2, 'EMP002', '佐藤花子', 'アプリ', '一般');


-- -- -----------------------------------------------------
-- -- Table `assins` (アサインテーブル)
-- -- ご提示の画像構成に基づきます。
-- -- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS assins (
--     assins_id INT AUTO_INCREMENT PRIMARY KEY, -- テーブル管理用ID
--     user_account_code VARCHAR(30) NOT NULL, -- ユーザーアカウントコード (usersテーブルのaccount_codeを想定)
--     assin_month INT NOT NULL,               -- 月 (何月のデータか)
--     assin_total DECIMAL(10,2) NOT NULL,     -- 合計 (DECIMAL(5,2)では999.99までなので、10,2に拡張)
--     assin_execution DECIMAL(10,2),          -- 実行
--     assin_maintenance DECIMAL(10,2),        -- 保守
--     assin_prospect DECIMAL(10,2),           -- 見込
--     assin_common_cost DECIMAL(10,2),        -- 共通(原価)
--     assin_most_com_ps DECIMAL(10,2),        -- 大共通PS
--     assin_sales_mane DECIMAL(10,2),         -- 営支(販管)
--     assin_investigation DECIMAL(10,2),      -- 調検
--     assin_project_code VARCHAR(30) NOT NULL, -- PJコード (projectsテーブルのproject_codeを想定)
--     assin_directly DECIMAL(10,2),           -- 直接
--     assin_common DECIMAL(10,2),             -- 共通
--     assin_sales_sup DECIMAL(10,2),          -- 営支
    
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 作成日時 (管理用)
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- 更新日時 (管理用)

--     -- 同じユーザー、同じ月、同じプロジェクトコードで重複がないことを保証するユニークキー
--     UNIQUE KEY uk_assins_user_month_project (user_account_code, assin_month, assin_project_code)
-- );

