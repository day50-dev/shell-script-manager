# ursh Registry Website

Full-stack web application for browsing and submitting urshies.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | React + Vite + Bootstrap |
| Backend | Node.js + Express |
| Database | SQLite |
| Auth | GitHub OAuth (optional) |
| Deployment | Docker + nginx |

## Features

- **Browse urshies** - Search and filter by tags
- **Submit urshies** - URL-only submission with auto-inference
- **User dashboard** - Track your submissions
- **Review queue** - Flagged submissions for manual review
- **REST API** - Programmatic access to registry

## Quick Start

```bash
cd website

# Option 1: Docker
docker-compose up

# Option 2: Manual
./start.sh
```

## Directory Structure

```
website/
├── backend/
│   ├── server.js          # Express server
│   ├── routes/            # API endpoints
│   ├── config/            # Database, OAuth
│   └── middleware/        # Auth, validation
├── frontend/
│   ├── src/
│   │   ├── pages/         # React pages
│   │   ├── components/    # Reusable components
│   │   └── services/      # API client
│   └── public/
└── database/
    └── init-db.js         # Schema + seed data
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/urshies` | GET | List all urshies |
| `/api/urshies/:id` | GET | Get urshie by ID |
| `/api/urshies/infer` | POST | Infer manifest from URL |
| `/api/submissions` | GET | List submissions |
| `/api/stats` | GET | Platform statistics |

## Anonymous Mode

The site works without GitHub OAuth. Users can:
- Browse all urshies
- Submit new urshies (anonymous)
- View submission status

OAuth is only required for:
- Managing your submissions
- Admin review functions
