# 🌍 GeoProperty Intelligence Platform

An AI-powered, enterprise-grade GeoProperty Intelligence Platform built with **Flutter**, **FastAPI**, **PostgreSQL**, and **PostGIS** for intelligent land records visualization, property analysis, and GIS-based property management.

The platform integrates with **Maharashtra BhuNaksha** to provide survey maps, property information, owner details, and interactive GIS visualization while leveraging PostgreSQL caching for high-performance data retrieval.

---

# ✨ Features

## 📍 GIS Property Visualization

- Interactive Flutter map using FlutterMap
- OpenStreetMap base layer
- Maharashtra BhuNaksha WMS overlay
- Survey polygon visualization
- Property highlighting
- Current location support

---

## 🏠 Property Information

- Survey search
- Owner details
- Property boundaries
- Land area
- Plot extent
- GIS Code lookup

---

## ⚡ Performance Optimization

- PostgreSQL metadata caching
- Village GeoJSON caching
- Reduced external API calls
- Faster map rendering
- Enterprise repository architecture

---

## 🗺 Spatial Technologies

- PostgreSQL
- PostGIS
- GeoJSON
- WMS
- GIS Coordinate Transformations
- Polygon Processing

---

# 🏗 Architecture

```
Flutter
        │
        ▼
FastAPI REST API
        │
        ▼
Service Layer
        │
        ▼
────────────────────────────────────────
│                                      │
▼                                      ▼
Cache Repository                Remote Repository
(PostgreSQL)                    (BhuNaksha)
│                                      │
└──────────────┬───────────────────────┘
               ▼
         Response to Client
```

---

# 📂 Project Structure

```
backend/
│
├── app/
│
├── api/
│   ├── v1/
│   └── v2/
│
├── core/
│
├── database/
│   ├── base.py
│   ├── session.py
│   └── models/
│
├── providers/
│
├── repositories/
│   ├── remote/
│   └── cache/
│
├── schemas/
│
├── services/
│
├── utils/
│
└── main.py
```

---

# 🛠 Tech Stack

## Frontend

- Flutter
- Flutter Riverpod
- Go Router
- FlutterMap
- Geolocator

---

## Backend

- FastAPI
- Pydantic
- SQLAlchemy
- HTTPX

---

## Database

- PostgreSQL
- PostGIS

---

## GIS

- OpenStreetMap
- Maharashtra BhuNaksha
- GeoJSON
- WMS

---

# 🗄 Database Tables

## Master Tables

- States
- Districts
- Talukas
- Villages

## Cache Tables

- Village Map Cache

## Planned

- Survey Cache
- Property Cache

---

# 🚀 Current Architecture

```
Flutter

↓

FastAPI

↓

Services

↓

Repositories

      ┌────────────────────┐
      │                    │
      ▼                    ▼

 Remote Repository     Cache Repository

(BhuNaksha)           (PostgreSQL)
```

---

# 📡 API Modules

## Location

- Districts
- Talukas
- Villages
- GIS Code Resolution

---

## Survey

- Survey Search
- Survey Details

---

## Property

- Property Information
- Owner Details
- Polygon Information

---

## Map

- Village GeoJSON
- Property Polygon
- Plot Extent

---

# ⚡ Performance Strategy

## Metadata Cache

```
Districts

↓

Talukas

↓

Villages
```

Data is cached in PostgreSQL after the first request to reduce repeated calls to BhuNaksha.

---

## Village Map Cache

The first request retrieves GeoJSON from BhuNaksha and stores it in PostgreSQL.

Subsequent requests serve the cached GeoJSON, significantly reducing response time.

---

# 🏛 Repository Pattern

```
Service

↓

Repository

↓

Remote Repository
(BhuNaksha)

OR

Cache Repository
(PostgreSQL)
```

---

# 📍 Current Development Status

## ✅ Completed

- FastAPI Backend
- Flutter Frontend
- PostgreSQL Integration
- PostGIS Setup
- GIS Visualization
- Repository Pattern
- Database Layer Refactoring
- SQLAlchemy Models
- WMS Integration
- Village Polygon Rendering

---

## 🚧 In Progress

- District Cache
- Taluka Cache
- Village Cache
- Village GeoJSON Cache

---

## 📅 Planned

- Survey Cache
- Property Cache
- PostGIS Geometry Storage
- Background Synchronization
- Redis Integration (Optional)
- Analytics Dashboard

---

# 🚀 Getting Started

## Backend

Clone the repository

```bash
git clone <repository-url>
cd backend
```

Create a virtual environment

```bash
python -m venv venv
```

Activate the virtual environment

### Windows

```bash
venv\Scripts\activate
```

Install dependencies

```bash
pip install -r requirements.txt
```

Run the backend

```bash
python main.py
```

or

```bash
uvicorn main:app --reload
```

---

## Flutter

```bash
flutter pub get

flutter run
```

---

# 📖 Roadmap

- [x] Backend Architecture Refactoring
- [x] PostgreSQL Integration
- [x] PostGIS Installation
- [x] Repository Pattern
- [ ] District Cache
- [ ] Taluka Cache
- [ ] Village Cache
- [ ] Village GeoJSON Cache
- [ ] Survey Cache
- [ ] Property Cache
- [ ] Background Sync
- [ ] PostGIS Spatial Queries
- [ ] Redis Cache
- [ ] AI Property Insights

---

# 🤝 Contributing

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/my-feature
```

3. Commit your changes

```bash
git commit -m "feat: add new feature"
```

4. Push to your branch

```bash
git push origin feature/my-feature
```

5. Open a Pull Request

---

# 📄 License

This project is intended for educational and research purposes.

---

# 👨‍💻 Author

**Nitin Balwant Panzade**

B.Tech Computer Science & Engineering (AI)

Vishwakarma Institute of Information Technology (VIIT), Pune

---

⭐ If you find this project useful, consider giving it a star!
