FROM python:3.13 AS build

ARG RESUME

RUN apt-get update && \
    apt-get install -y build-essential libxml2-dev libxslt1-dev libffi-dev libz-dev libcairo2 libglib2.0-0 libpango-1.0-0 libpangocairo-1.0-0

COPY . /app
WORKDIR /app
RUN pip3 install --no-cache-dir -r requirements.txt && \
    make

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
RUN echo "server_tokens off;" >> /etc/nginx/conf.d/default.conf

EXPOSE 80
