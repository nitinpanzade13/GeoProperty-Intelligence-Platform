# GeoProperty Intelligence Platform (Property Radar) - Architecture Documentation

## Overview
Property Radar is an enterprise-grade, AI-ready land and property intelligence platform built with Flutter and FastAPI. It adheres strictly to Clean Architecture, SOLID principles, and MVVM design patterns.

## Directory Layout
- `flutter/`: Cross-platform mobile/desktop client.
- `backend/`: FastAPI Python microservice layer.
- `docs/`: System documentation and API reference.

## Clean Architecture Layers

```
         Presentation Layer (MVVM Views & ViewModels / Riverpod)
                                   │
                                   ▼
         Domain Layer (Entities, Use Cases, Core Interfaces)
                                   │
                                   ▼
         Repository Layer (Data Repositories, Caching Strategy)
                                   │
                                   ▼
         Data Layer (API Clients, Dio, Local Storage Hive)
                                   │
                                   ▼
         External Services (GIS Providers, Geolocator, Google Maps)
```

## Backend Microservice Layer
FastAPI backend utilizes Pydantic for validation, dependency injection for repositories/services, and asynchronous request handling for enterprise performance.
