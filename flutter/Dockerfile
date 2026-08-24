FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL

# Fail the build if Coolify did not provide the API URL.
RUN test -n "$API_BASE_URL" || \
    (echo "ERROR: API_BASE_URL build argument is empty!" && exit 1)

# Show exactly which API URL is being baked into Flutter.
RUN echo "Building Flutter with API_BASE_URL=$API_BASE_URL"

RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL="$API_BASE_URL"

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
