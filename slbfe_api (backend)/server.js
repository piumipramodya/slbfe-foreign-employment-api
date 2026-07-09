const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer'); 
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs'); // INDUSTRY GOOD PRACTICE: Secure hashing 
const Citizen = require('./Citizen');

const app = express();
app.use(express.json()); 
app.use(cors());

// --- REQUIREMENT (iii/viii): STATIC FILE SERVING ---
// Allows Bureau Officers to view job seeker certificates and CVs [cite: 14, 28]
app.use('/uploads', express.static('uploads'));

// 1. Database Connection
mongoose.connect('mongodb+srv://piuminanayakkara24:SaBrHxxIwgS4bTTR@cluster0.jnjybxm.mongodb.net/SLBFE_DB?retryWrites=true&w=majority')
    .then(() => console.log("✅ Connected to MongoDB Atlas with Security Enabled"))
    .catch(err => console.log("❌ MongoDB Error:", err));

// --- REQUIREMENT (ii): MULTER CONFIGURATION ---
if (!fs.existsSync('./uploads')) {
    fs.mkdirSync('./uploads');
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, './uploads');
    },
    filename: (req, file, cb) => {
        // Industry practice: Prevent overwriting with unique timestamps 
        cb(null, `${req.params.nid}-${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
    }
});

const upload = multer({ storage: storage });

// --- THE FIX: ROBUST NID QUERY ---
const getNidQuery = (nid) => ({
    nid: { $regex: new RegExp("^\\s*" + nid.trim() + "\\s*$", "i") }
});

// --- API ROUTES ---

// 1. MEMBER REGISTRATION (Requirement i)
// Citizens and officers can register themselves securely [cite: 12, 23, 24]
app.post('/citizens', async (req, res) => {
    try {
        if (req.body.nid) req.body.nid = req.body.nid.toString().trim();
        
        // --- SECURITY: PASSWORD HASHING ---
        // Conforming to Industry Good Practice for data protection 
        const salt = await bcrypt.genSalt(10);
        req.body.password = await bcrypt.hash(req.body.password, salt);

        const newCitizen = new Citizen(req.body);
        await newCitizen.save();
        res.status(201).json({ message: "Registration successful" });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

// 2. USER AUTHENTICATION (Requirement iii/vii)
// Verifies hashed credentials for secure portal access [cite: 38, 41]
app.post('/citizens/login', async (req, res) => {
    try {
        const { nid, password } = req.body;
        const citizen = await Citizen.findOne(getNidQuery(nid));

        if (!citizen) return res.status(404).json({ message: "NID not registered" });

        // --- SECURITY: BCRYPT COMPARISON ---
        const isMatch = await bcrypt.compare(password, citizen.password);
        if (!isMatch) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        // Determine role based on 'affiliation' (SLBFE = Officer) [cite: 14, 24]
        const role = citizen.affiliation?.toUpperCase() === 'SLBFE' ? 'officer' : 'citizen';

        res.json({ 
            message: "Login successful", 
            role: role, 
            name: citizen.name, 
            nid: citizen.nid 
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 3. IDENTITY STATUS CHECK (Requirement iii)
app.get('/citizens/status/:nid', async (req, res) => {
    const searchNid = req.params.nid.trim();
    try {
        const citizen = await Citizen.findOne(getNidQuery(searchNid));
        if (!citizen) return res.status(404).json({ message: "NID not found" });
        
        res.json({ 
            name: citizen.name, 
            isVerified: citizen.isVerified || false,
            currentLat: citizen.location ? citizen.location.lat : 6.9271,
            currentLong: citizen.location ? citizen.location.long : 79.8612
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 4. UPDATE QUALIFICATIONS & UPLOAD DOCUMENTS (Requirement ii)
// Facilitates job seeker document submissions [cite: 13, 25, 26]
app.put('/citizens/:nid/documents', upload.fields([
    { name: 'birthCertificate', maxCount: 1 },
    { name: 'cv', maxCount: 1 },
    { name: 'passportCopy', maxCount: 1 }
]), async (req, res) => {
    try {
        const searchNid = req.params.nid.trim();
        const updateData = { $set: {} };
        
        if (req.body.qualifications && req.body.qualifications !== "") {
            updateData.$push = { qualifications: req.body.qualifications };
        }

        if (req.files) {
            if (req.files['birthCertificate']) updateData.$set.birthCertificate = req.files['birthCertificate'][0].path;
            if (req.files['cv']) updateData.$set.cv = req.files['cv'][0].path;
            if (req.files['passportCopy']) updateData.$set.passportCopy = req.files['passportCopy'][0].path;
        }

        const updated = await Citizen.findOneAndUpdate(
            getNidQuery(searchNid),
            updateData,
            { new: true }
        );

        if (!updated) return res.status(404).json({ message: "Citizen record not found" });
        res.json({ message: "Update successful", data: updated });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 5. OFFICER VALIDATION (Requirement iii)
// Allows bureau officers to verify member information [cite: 14, 30]
app.patch('/citizens/:nid/verify', async (req, res) => {
    try {
        const updated = await Citizen.findOneAndUpdate(
            getNidQuery(req.params.nid), 
            { isVerified: true }, 
            { new: true }
        );
        if (!updated) return res.status(404).json({ message: "NID not found" });
        res.json({ message: "Verified successfully", data: updated });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 6. UPDATE FOREIGN LOCATION (Requirement vi)
// Monitoring wellbeing of foreign employees [cite: 9, 16]
app.put('/citizens/:nid/location', async (req, res) => {
    try {
        const { lat, long } = req.body;
        const updated = await Citizen.findOneAndUpdate(
            getNidQuery(req.params.nid),
            { $set: { "location.lat": lat, "location.long": long } },
            { new: true }
        );
        if (!updated) return res.status(404).json({ message: "NID not found" });
        res.json(updated);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 7. COMPLAINT MANAGEMENT (Requirement vii)
// Handling family complaints and officer replies [cite: 9, 17]
app.post('/citizens/:nid/complaint', async (req, res) => {
    try {
        const { message } = req.body;
        const updated = await Citizen.findOneAndUpdate(
            getNidQuery(req.params.nid),
            { $push: { complaints: { message, date: new Date(), reply: "" } } },
            { new: true }
        );
        if (!updated) return res.status(404).json({ message: "NID not found" });
        res.json(updated);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.patch('/citizens/:nid/complaint/:complaintId', async (req, res) => {
    try {
        const updated = await Citizen.findOneAndUpdate(
            { ...getNidQuery(req.params.nid), "complaints._id": req.params.complaintId },
            { $set: { "complaints.$.reply": req.body.reply } },
            { new: true }
        );
        if (!updated) return res.status(404).json({ message: "Complaint ID not found" });
        res.json(updated);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 8. COMPANY SEARCH (Requirement v)
// Foreign companies finding workers based on qualifications [cite: 15, 31, 32]
app.get('/citizens/find/search', async (req, res) => {
    try {
        const { qualification } = req.query;
        const workers = await Citizen.find({ 
            qualifications: { $regex: new RegExp(qualification, "i") }, 
            isVerified: true, 
            status: 'active' 
        });
        res.json(workers);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 9. REQUIREMENT (viii): EMERGENCY CONTACTS 
app.get('/citizens/:nid/contacts', async (req, res) => {
    try {
        const searchNid = req.params.nid.trim();
        const citizen = await Citizen.findOne(getNidQuery(searchNid)).select('emergencyContact name');
        if (!citizen) return res.status(404).json({ message: "NID not found" });
        res.json(citizen.emergencyContact); 
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 10. DEACTIVATE ACCOUNT (Requirement vii)
// Staff deactivating accounts for deceased individuals [cite: 33, 34]
app.delete('/citizens/:nid', async (req, res) => {
    try {
        const searchNid = req.params.nid.trim();
        const updated = await Citizen.findOneAndUpdate(
            getNidQuery(searchNid), 
            { status: 'deactivated' }, 
            { new: true }
        );
        if (!updated) return res.status(404).json({ message: "NID not found" });
        res.json({ message: "Account successfully deactivated", data: updated });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 11. ACCESS FULL PROFILE & OFFICER DASHBOARD (Requirement iii)
app.get('/citizens/:nid', async (req, res) => {
    try {
        const citizen = await Citizen.findOne(getNidQuery(req.params.nid));
        if (!citizen) return res.status(404).json({ message: "Citizen not found" });
        res.json(citizen);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/citizens', async (req, res) => {
    try {
        const citizens = await Citizen.find(); 
        res.json(citizens);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

const PORT = 5000;
app.listen(PORT, () => console.log(`🚀 Secure SLBFE Server running on port ${PORT}`));