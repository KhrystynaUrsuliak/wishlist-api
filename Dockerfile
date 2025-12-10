# ---- Build Stage ----
# На цьому етапі ми встановлюємо залежності у віртуальне оточення
FROM python:3.11-slim as builder

# Встановлюємо Poetry для кращого керування залежностями (рекомендовано)
# Або можна залишити pip, якщо ви не використовуєте poetry
WORKDIR /app
COPY requirements.txt .

# Створюємо віртуальне оточення
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Встановлюємо залежності
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# ---- Final Stage ----
# На цьому етапі ми створюємо чистий образ для запуску
FROM python:3.11-slim

# Створюємо користувача та групу з обмеженими правами
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Копіюємо віртуальне оточення з етапу 'builder'
COPY --from=builder /opt/venv /opt/venv

# Встановлюємо PATH, щоб система бачила пакети з venv
ENV PATH="/opt/venv/bin:$PATH"

# Встановлюємо робочу директорію та копіюємо код
WORKDIR /app
COPY . .

# Надаємо права новому користувачу
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8000

# Health Check для перевірки стану сервісу
# Переконайтесь, що у вашому FastAPI є ендпоінт /health, який повертає 200 OK
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Команда для запуску Gunicorn (краще для production, ніж Uvicorn)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
