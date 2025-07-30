-- データベースが存在しなければ作成し、使用する
CREATE DATABASE IF NOT EXISTS my_test_db;
USE my_test_db;

-- -----------------------------------------------------
-- Table `projects` (プロジェクトマスター - SCD Type 2適用)
-- ご提示のprojectsテーブル定義に基づき、SCD Type 2のためのカラムを含みます。
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY, -- テーブル管理用ID
    project_br_num VARCHAR(30) NOT NULL,         -- PJコード枝番 (UNIQUE制約はproject_br_numとvalid_fromの複合で)
    project_name VARCHAR(100) NOT NULL,        -- PJ名称
    project_contract_form VARCHAR(30),         -- PJ契約形態
    project_sched_self DATE,                 -- 予定期間(自)
    project_sched_to DATE,                   -- 予定期間(至)
    project_type_name VARCHAR(30),             -- PJタイプ名称
    project_classification VARCHAR(30),        -- PJ分類
    project_estimate_num VARCHAR(30),        -- 実行予算見積番号
    
    -- SCD Type 2 のためのカラム
    valid_from DATE NOT NULL,                  -- 有効期間開始日 (CSV読み込み時の日付)
    valid_to DATE,                             -- 有効期間終了日 (NULLなら現在有効、新データ読み込み時の前日)
    is_current TINYINT(1) NOT NULL,            -- 有効かどうか (TRUE=1, FALSE=0)

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_project_br_num_valid_from (project_br_num, valid_from)
);

-- -----------------------------------------------------
-- ストアドプロシージャ: `UpdateProjectSCD2`
-- 新しいプロジェクトデータを受け取り、SCD Type 2ロジックでprojectsテーブルを更新する。
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE UpdateProjectSCD2(
    IN p_project_br_num VARCHAR(30),
    IN p_project_name VARCHAR(100),
    IN p_project_contract_form VARCHAR(30),
    IN p_project_sched_self DATE,
    IN p_project_sched_to DATE,
    IN p_project_type_name VARCHAR(30),
    IN p_project_classification VARCHAR(30),
    IN p_project_estimate_num VARCHAR(30)
    -- IN p_is_flag TINYINT(1) -- is_flagがない場合はこの行をコメントアウト
)
BEGIN
    DECLARE v_current_id INT;
    DECLARE v_is_changed BOOLEAN DEFAULT FALSE; -- 変更があったかどうかのフラグ
    DECLARE v_today DATE DEFAULT CURDATE();     -- 今日の日付
    DECLARE v_yesterday DATE DEFAULT (CURDATE() - INTERVAL 1 DAY); -- 昨日の日付

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- 必要であれば、エラーメッセージをログに記録したり、別のテーブルに挿入したりできます
        -- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SCD Type 2 update failed due to SQL error';
    END;

    -- トランザクション開始
    START TRANSACTION;

    -- (1) 現在有効な既存レコードのIDと内容を取得
    SELECT
        id,
        (
            p_project_name <> project_name OR
            COALESCE(p_project_contract_form, '') <> COALESCE(project_contract_form, '') OR
            COALESCE(p_project_sched_self, '1000-01-01') <> COALESCE(project_sched_self, '1000-01-01') OR
            COALESCE(p_project_sched_to, '1000-01-01') <> COALESCE(project_sched_to, '1000-01-01') OR
            COALESCE(p_project_type_name, '') <> COALESCE(project_type_name, '') OR
            COALESCE(p_project_classification, '') <> COALESCE(project_classification, '') OR
            COALESCE(p_project_estimate_num, '') <> COALESCE(project_estimate_num, '')
            -- COALESCE(p_is_flag, 0) <> COALESCE(is_flag, 0) -- is_flagがない場合はコメントアウト
        )
    INTO v_current_id, v_is_changed
    FROM projects
    WHERE project_br_num = p_project_br_num AND is_current = 1;

    -- (2) 変更があった場合、古いレコードを無効化
    IF v_current_id IS NOT NULL AND v_is_changed THEN
        UPDATE projects
        SET
            valid_to = v_yesterday,
            is_current = 0, -- FALSE
            updated_at = NOW()
        WHERE id = v_current_id;
    END IF;

    -- (3) 新しいレコードを挿入 (新規の場合、または変更があった場合)
    IF v_current_id IS NULL OR v_is_changed THEN
        INSERT INTO projects (
            project_br_num, project_name, project_contract_form, project_sched_self, project_sched_to,
            project_type_name, project_classification, project_estimate_num,
            valid_from, valid_to, is_current, created_at, updated_at
            -- is_flag -- is_flagがない場合はコメントアウト
        ) VALUES (
            p_project_br_num, p_project_name, p_project_contract_form, p_project_sched_self, p_project_sched_to,
            p_project_type_name, p_project_classification, p_project_estimate_num,
            v_today, NULL, 1, NOW(), NOW()
            -- p_is_flag -- is_flagがない場合はコメントアウト
        );
    END IF;

    COMMIT; -- 変更を確定

EXCEPTION WHEN OTHERS THEN
    ROLLBACK; -- エラーがあれば元に戻す
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SCD Type 2 update failed';
END //

DELIMITER ;

-- -----------------------------------------------------
-- (オプション) サンプルデータの挿入 (ストアドプロシージャの動作確認用)
-- -----------------------------------------------------
-- 初期データ
CALL UpdateProjectSCD2(
    'PJ001', '初期プロジェクトA', '請負', '2024-01-01', '2024-06-30', 'システム開発', '新規', 'EST-001'
);
CALL UpdateProjectSCD2(
    'PJ002', '初期プロジェクトB', '準委任', '2024-03-01', '2024-12-31', 'インフラ構築', '既存改修', 'EST-002'
);


-- -- -----------------------------------------------------
-- -- サンプルデータの挿入 (オプション)
-- -- -----------------------------------------------------
-- INSERT IGNORE INTO projects (project_id, project_br_num, project_name, project_contract_form, project_sched_self, project_sched_to, project_type_name, project_classification, project_estimate_num, project_valid_from, project_valid_to, project_is_current) VALUES
-- (101, 'PJ001', '新機能開発X', '請負', '2024-01-01', '2024-06-30', 'システム開発', 'PS', 'EST-001', '2024-01-01', NULL, TRUE),
-- (102, 'PJ002', '既存システム改修Y', '準委任', '2024-03-15', '2024-12-31', 'システム開発', 'PS', 'EST-002', '2024-03-15', NULL, TRUE);

-- -- ★★★ ここから追記 ★★★
-- -- 'user'ユーザーが存在しない場合に作成し、パスワードを設定
-- -- IDENTIFIED BY 'pass' は docker-compose.yml の MYSQL_PASSWORD と一致させる
-- CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'pass';

-- -- 'user'ユーザーに my_test_db データベースへの全ての権限を付与
-- -- '@'%' は、どのホスト（IPアドレス）からでも接続を許可するという意味
-- GRANT ALL PRIVILEGES ON my_test_db.* TO 'user'@'%';