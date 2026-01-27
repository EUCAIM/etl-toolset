FROM python:3.9-slim
WORKDIR /app
COPY ./requirements.txt /app
RUN pip install --prefer-binary --no-cache-dir -r requirements.txt
COPY . .
RUN chmod o+rw /app /app/hosted /app/results
ENV FLASK_APP=app.py
EXPOSE 5000
VOLUME ["/app/results"]
CMD ["flask", "run" , "--host", "0.0.0.0", "--port", "5000"]
