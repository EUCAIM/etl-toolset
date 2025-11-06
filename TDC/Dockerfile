FROM python:3.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ gcc make \
    libfftw3-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./requirements.txt /app

RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install --no-cache-dir cython numpy \
 && pip install --no-cache-dir -r requirements.txt

COPY . .
ENV FLASK_APP=app.py
EXPOSE 5000
VOLUME ["/app/results"]
CMD ["flask", "run" , "--host", "0.0.0.0", "--port", "5000"]
