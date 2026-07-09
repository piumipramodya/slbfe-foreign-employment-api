const mongoose = require('mongoose');

const citizenSchema = new mongoose.Schema({
    // --- IDENTITY & REGISTRATION (Requirement i) ---
    // Registers a member with NID, name, age, address, email, and affiliation [cite: 23, 24]
    nid: { 
        type: String, 
        required: true, 
        unique: true, 
        trim: true,
        index: true 
    }, 
    name: { type: String, required: true, trim: true },
    age: { type: Number, required: true },
    address: { type: String, trim: true }, 
    email: { type: String, trim: true, lowercase: true }, 
    profession: { type: String, trim: true },
    affiliation: { type: String, trim: true }, 
    password: { type: String, required: true },
    
    // --- JOB SEEKER DATA (Requirement ii) ---
    // Job seekers update qualifications and upload certificates/CVs [cite: 13, 25, 26]
    qualifications: [String], 
    birthCertificate: { type: String, default: "" }, 
    cv: { type: String, default: "" },               
    passportCopy: { type: String, default: "" },     

    // --- ADMINISTRATIVE STATUS (Requirement iii/vii) ---
    // Officers validate information and deactivate accounts for deceased citizens [cite: 14, 30, 33, 34]
    isVerified: { type: Boolean, default: false },
    status: { type: String, default: 'active' }, 
    
    // --- GEOLOCATION (Requirement vi) ---
    // Foreign employees update coordinates upon arrival at a foreign company [cite: 16]
    location: {
        lat: { type: Number, default: 6.9271 },
        long: { type: Number, default: 79.8612 }
    },

    // --- CONTACT INFORMATION (Requirement viii) ---
    // Staff collects information about emergency contacts for any citizen [cite: 35, 36]
    emergencyContact: {
        contactName: { type: String, default: "Not Provided" },
        contactPhone: { type: String, default: "Not Provided" },
        relationship: { type: String, default: "Next of Kin" }
    },

    // --- COMPLAINT MANAGEMENT (Requirement vii) ---
    // Citizens lodge complaints and officers reply via the system [cite: 17]
    complaints: [{
        message: { type: String, required: true },
        date: { type: Date, default: Date.now },
        reply: { type: String, default: "" }
    }]
}, { 
    timestamps: true // Useful for auditing registration and update dates [cite: 38]
});

module.exports = mongoose.model('Citizen', citizenSchema);