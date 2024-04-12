FROM python:3.11-alpine
LABEL maintainer="parthsuva911@gmail.com"
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 9090
ENTRYPOINT ["python"]
CMD ["app.py"]