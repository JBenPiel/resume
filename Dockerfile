# syntax=docker/dockerfile:1
# HTML and PDF output is shared by both target architectures.
FROM --platform=$BUILDPLATFORM python:3.14 AS build

ARG RESUME

RUN apt-get update && \
    apt-get install -y build-essential libxml2-dev libxslt1-dev libffi-dev libz-dev libcairo2 libglib2.0-0 libpango-1.0-0 libpangocairo-1.0-0

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY main.py Makefile nginx.conf ./
COPY resumes/ ./resumes/
COPY themes/ ./themes/
RUN make

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY --from=build /app/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
