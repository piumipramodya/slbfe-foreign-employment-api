# SLBFE Foreign Employment Management System

A **RESTful Web API** developed for the Sri Lanka Bureau of Foreign Employment (SLBFE) as part of the CS406.3 coursework.

## ✨ Project Overview

This system modernizes SLBFE services by enabling:
- Free citizen registration
- Job seekers to update qualifications and upload documents
- Bureau officers to verify information and manage complaints
- Foreign companies to search for workers by qualifications
- Overseas employees to update their current location
- A secure complaint lodging and resolution system

## 🛠️ Technologies Used

- **Backend**: Node.js + Express.js
- **Database**: MongoDB Atlas
- **Security**: Bcryptjs (password hashing)
- **Client Application**: Flutter Mobile App
- **Testing**: Postman

## 📁 Project Structure

- `controllers/` → API route handlers
- `models/` → Mongoose schemas
- `routes/` → API endpoints
- `middleware/` → Authentication & file upload
- `client/` → Flutter mobile application
- `docs/` → Full coursework report + screenshots

## 📋 API Documentation

Detailed API documentation is available in the project report: [`29366_CS406.3_SLBFE_API_Report.pdf`](./docs/29366_CS406.3_SLBFE_API_Report.pdf).

**Key Endpoints include:**
- `POST /citizens` → Member Registration
- `PUT /citizens/:nid/documents` → Upload qualifications & documents
- `GET /citizens/:nid` → Retrieve member profile
- `PATCH /citizens/:nid/verify` → Officer verification
- `GET /citizens/find/search` → Search candidates by qualification
- `PUT /citizens/:nid/location` → Update overseas location
- `POST /citizens/:nid/complaint` → Lodge complaint
- `PATCH /citizens/:nid/complaint/:id` → Officer reply to complaint

## 🚀 How to Run

Detailed setup instructions, database configuration, and testing steps are available in the full report located in the `docs/` folder.


## 📄 Project Report

The complete project report, including API documentation, screenshots, industry standards, client application description, and implementation details, is available in the `docs` folder.

**Report:** [`29366_CS406.3_SLBFE_API_Report.pdf`](./docs/29366_CS406.3_SLBFE_API_Report.pdf)


## 👤 Author

- **Name**: N.W.P.P.P. Nanayakkara
- **Degree**: BSc (Hons) in Computer Systems Engineering
- **University**: NSBM Green University

---

**Course**: Web Architecture and Web Development Technologies (CS406.3)  
**Academic Year**: 2025/2026
