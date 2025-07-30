FROM python:3.11-slim

WORKDIR /app

# OSレベルの依存関係（pymysql用など）
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-libmysqlclient-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 依存関係ファイルをコピーしてインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# スクリプト自体は volumes でマウントするので COPY は不要
