/**
 * seed.js — Triple-Lock Security Protocol Seeder for the Attendance App
 *
 * Run with:  node src/seed.js
 *
 * What it creates
 * ───────────────
 *  Staff   :  1 Staff user  →  Dr. Aris  (staff@test.com)
 *  Classes :  3 classes taught by Dr. Aris
 *               • Mobile App Development   (BSSID: "2c:fd:a1:b3:e5:10")
 *               • Database Systems         (BSSID: "aa:bb:cc:11:22:33")
 *               • Network Security         (BSSID: "dd:ee:ff:44:55:66")
 *  Students:  10 mock students distributed across the 3 classes
 *  Attendance: 30 records across the last 7 days (mix of PRESENT / ABSENT)
 *    - Includes Triple-Lock flagged records with audit selfie URLs
 *    - Includes records with biometric signature changes
 *
 * Login credentials (password → "Password@123")
 * ────────────────────────────────────────────────
 *  staff@test.com                 STAFF  (Dr. Aris)
 *  student01@test.com … student10@test.com   STUDENT
 */

require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const User = require("./models/User");
const Class = require("./models/Class");
const Attendance = require("./models/Attendance");

// ─── helpers ──────────────────────────────────────────────────────────────────
const pad = (n) => String(n).padStart(2, "0");
const dateStr = (d) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const timeStr = (h, m) => `${pad(h)}:${pad(m)}:00`;

/** Returns a Date object `n` days before today. */
function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

/** 60% PRESENT · 15% ABSENT · 10% LATE · 15% FLAGGED-PRESENT */
function randomStatus() {
  const r = Math.random();
  if (r < 0.6) return "PRESENT";
  if (r < 0.75) return "ABSENT";
  if (r < 0.85) return "LATE";
  return "FLAGGED"; // special case — PRESENT but flagged for review
}

/** Pick a random integer in [min, max] inclusive. */
function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/** Pick a random element from an array. */
function pick(arr) {
  return arr[randInt(0, arr.length - 1)];
}

// ─── main ──────────────────────────────────────────────────────────────────────
async function seed() {
  console.log("🌱  Connecting to MongoDB…");
  console.log(
    "    URI:",
    process.env.MONGO_URI
      ? process.env.MONGO_URI.replace(/:([^@]+)@/, ":***@")
      : "NOT SET"
  );

  await mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 15_000,
    connectTimeoutMS: 15_000,
  });

  console.log(`✅  Connected to : ${mongoose.connection.host}`);
  console.log(`📊  Database     : ${mongoose.connection.name}\n`);

  // ── 0. Clear target collections ─────────────────────────────────────────────
  console.log(
    "🗑️   Clearing existing Staff / Class / Attendance collections…"
  );
  await Promise.all([
    User.deleteMany({}),
    Class.deleteMany({}),
    Attendance.collection.drop().catch(() => {}),
  ]);
  console.log("    Done.\n");

  // ── 1. Shared password ──────────────────────────────────────────────────
  const rawPw = "Password@123";

  // ── 2. Create Dr. Aris (STAFF) ───────────────────────────────────────────────
  console.log("👤  Creating Staff user — Dr. Aris…");

  const aris = await User.create({
    name: "Dr. Aris",
    email: "staff@test.com",
    password: rawPw,
    role: "STAFF",
    staffId: "STAFF-001",
    studentId: "STAFF-001",
    department: "Computer Science",
    phone: "9000000001",
    isActive: true,
  });

  console.log(`    ✅  Created: Dr. Aris  (id: ${aris._id})\n`);

  // ── 3. Create 10 mock students ───────────────────────────────────────────────
  console.log("🎓  Creating 10 mock students…");

  const studentRawData = [
    { name: "Jhon Doe",      email: "student01@test.com", id: "STU001", roll: "01" },
    { name: "Rohan Mehta",     email: "student02@test.com", id: "STU002", roll: "02" },
    { name: "Sneha Iyer",      email: "student03@test.com", id: "STU003", roll: "03" },
    { name: "Arjun Verma",     email: "student04@test.com", id: "STU004", roll: "04" },
    { name: "Meera Nair",      email: "student05@test.com", id: "STU005", roll: "05" },
    { name: "Karan Singh",     email: "student06@test.com", id: "STU006", roll: "06" },
    { name: "Priya Das",       email: "student07@test.com", id: "STU007", roll: "07" },
    { name: "Vikram Bose",     email: "student08@test.com", id: "STU008", roll: "08" },
    { name: "Ananya Krishnan", email: "student09@test.com", id: "STU009", roll: "09" },
    { name: "Dev Sharma",      email: "student10@test.com", id: "STU010", roll: "10" },
  ];

  const students = await User.insertMany(
    studentRawData.map((s) => ({
      name: s.name,
      email: s.email,
      password: rawPw,
      role: "STUDENT",
      studentId: s.id,
      rollNo: s.roll,
      department: "Computer Science",
      semester: 4,
      isActive: true,
    }))
  );


  console.log(`    ✅  Created ${students.length} students.\n`);

  // ── 4. Distribute students across 3 classes ──────────────────────────────────
  const shuffled = [...students].sort(() => Math.random() - 0.5);
  const groupA = shuffled.slice(0, 4);
  const groupB = shuffled.slice(4, 7);
  const groupC = shuffled.slice(7);

  console.log(
    `    Distribution → Class A: ${groupA.length} · Class B: ${groupB.length} · Class C: ${groupC.length}`
  );

  // ── 5. Create 3 Classes linked to Dr. Aris ──────────────────────────────────
  console.log("\n🏫  Creating 3 classes for Dr. Aris…");

  const classA = await Class.create({
    classCode: "MAD-SEM4",
    className: "Mobile App Development",
    department: "Computer Science",
    semester: 4,
    authorizedBssid: "2c:fd:a1:b3:e5:10",
    students: groupA.map((s) => s._id),
    totalStrength: groupA.length,
    location: {
      room: "Room 101",
      building: "CS Block",
      wifiRouter: "Router-MAD-101",
    },
    subjects: [
      {
        code: "CS401",
        name: "Mobile App Development",
        instructor: aris._id,
        schedule: { day: "Monday", time: "09:00", room: "101" },
      },
    ],
    createdBy: aris._id,
    isActive: true,
  });

  const classB = await Class.create({
    classCode: "DBS-SEM4",
    className: "Database Systems",
    department: "Computer Science",
    semester: 4,
    authorizedBssid: "aa:bb:cc:11:22:33",
    students: groupB.map((s) => s._id),
    totalStrength: groupB.length,
    location: {
      room: "Room 201",
      building: "CS Block",
      wifiRouter: "Router-DBS-201",
    },
    subjects: [
      {
        code: "CS402",
        name: "Database Systems",
        instructor: aris._id,
        schedule: { day: "Wednesday", time: "11:00", room: "201" },
      },
    ],
    createdBy: aris._id,
    isActive: true,
  });

  const classC = await Class.create({
    classCode: "NSE-SEM4",
    className: "Network Security",
    department: "Computer Science",
    semester: 4,
    authorizedBssid: "dd:ee:ff:44:55:66",
    students: groupC.map((s) => s._id),
    totalStrength: groupC.length,
    location: {
      room: "Room 301",
      building: "CS Block",
      wifiRouter: "Router-NSE-301",
    },
    subjects: [
      {
        code: "CS403",
        name: "Network Security",
        instructor: aris._id,
        schedule: { day: "Friday", time: "14:00", room: "301" },
      },
    ],
    createdBy: aris._id,
    isActive: true,
  });

  console.log(
    "    ✅  Created: Mobile App Development · Database Systems · Network Security\n"
  );

  // ── 6. 8 Periods per day — realistic timetable ──────────────────────────────
  const periodSubjects = [
    { period: 1, subject: "Mathematics",              courseCode: "MA401", time: "09:00:00" },
    { period: 2, subject: "Mobile App Development",   courseCode: "CS401", time: "09:50:00" },
    { period: 3, subject: "Database Systems",         courseCode: "CS402", time: "10:40:00" },
    { period: 4, subject: "Network Security",         courseCode: "CS403", time: "11:30:00" },
    { period: 5, subject: "Operating Systems",        courseCode: "CS404", time: "13:00:00" },
    { period: 6, subject: "Software Engineering",     courseCode: "CS405", time: "13:50:00" },
    { period: 7, subject: "Data Structures Lab",      courseCode: "CS406", time: "14:40:00" },
    { period: 8, subject: "Communication Skills",     courseCode: "HS401", time: "15:30:00" },
  ];

  // All students share the same class code for simplicity
  const defaultClassCode = classA.classCode;  // MAD-SEM4
  const defaultBssid     = classA.authorizedBssid;
  const defaultRouter    = "Router-MAD-101";

  // ── 7. Generate 8-period attendance records — last 45 weekdays ─────────────
  console.log(
    "📋  Generating 8-period/day attendance records (last 45 days) with Triple-Lock mock data…"
  );

  const attendanceDocs = [];
  const seen = new Set();
  let count = 0;
  let flaggedCount = 0;

  const flagReasons = [
    "New fingerprint enrolled on device — audit selfie captured",
    "Biometric domain state changed after device reset",
    "Face ID re-enrolled — forced face scan verification",
    "Second finger added to phone settings",
    "Biometric sensor data mismatch detected",
  ];

  for (let daysBack = 45; daysBack >= 1; daysBack--) {
    const date = daysAgo(daysBack);
    // Skip weekends
    if (date.getDay() === 0 || date.getDay() === 6) continue;

    const dateString = dateStr(date);
    const semester = daysBack > 20 ? 3 : 4;

    for (const student of students) {
      for (const ps of periodSubjects) {
        const key = `${student.studentId}|${dateString}|${defaultClassCode}|${ps.period}`;
        if (seen.has(key)) continue;
        seen.add(key);

        const rawStatus = randomStatus();
        const isFlagged = rawStatus === "FLAGGED";
        const status = isFlagged ? "PRESENT" : rawStatus;
        const isPresent = status === "PRESENT" || status === "LATE";

        let method, verificationMethod, securityTier;
        if (isFlagged) {
          method = "TripleLock";
          verificationMethod = "TripleLock-FaceScan";
          securityTier = "Tier3B-FaceScan";
          flaggedCount++;
        } else if (isPresent) {
          method = "TripleLock";
          verificationMethod = "TripleLock-Fingerprint";
          securityTier = "Tier3A-Fingerprint";
        } else {
          method = "manual";
          verificationMethod = "None";
          securityTier = "None";
        }

        attendanceDocs.push({
          studentId: student.studentId,
          studentName: student.name,
          date: dateString,
          time: ps.time,
          class: defaultClassCode,
          subject: ps.subject,
          period: ps.period,
          method,
          verificationMethod,
          bssid: isPresent ? defaultBssid : "unknown",
          deviceId: `device-${student.studentId}`,
          status,

          securityTier,
          biometricSignatureChanged: isFlagged,
          auditSelfieUrl: isFlagged
            ? `/uploads/audit-selfie-${student.studentId}-${dateString}-p${ps.period}.jpg`
            : null,
          flaggedForReview: isFlagged,
          flagReason: isFlagged ? pick(flagReasons) : null,

          faceVerified: isFlagged ? true : isPresent,
          fingerprintVerified: isFlagged ? false : isPresent,
          semester,
          courseCode: ps.courseCode,
          markedBy: student._id,
          wifiRouter: isPresent ? defaultRouter : "unknown",
          notes: isFlagged
            ? "⚠️ Flagged — biometric signature changed, audit selfie attached"
            : !isPresent
            ? "Absent – auto-recorded"
            : "✅ Triple-Lock fingerprint verification",
          reason: !isPresent && !isFlagged
            ? "Student not detected within authorized network"
            : null,
        });

        count++;
      }
    }
  }

  const insertResult = await Attendance.insertMany(attendanceDocs, {
    ordered: false,
  }).catch((err) => {
    if (err.code === 11000 || err.writeErrors) {
      console.warn(
        "    ⚠️  Some duplicate records skipped (expected on re-seed)."
      );
      return {
        insertedCount:
          attendanceDocs.length - (err.writeErrors?.length ?? 0),
      };
    }
    throw err;
  });

  const inserted =
    insertResult.length ?? insertResult.insertedCount ?? attendanceDocs.length;

  const presentCount = attendanceDocs.filter(
    (a) => a.status === "PRESENT"
  ).length;
  const absentCount = attendanceDocs.filter(
    (a) => a.status === "ABSENT"
  ).length;
  const lateCount = attendanceDocs.filter((a) => a.status === "LATE").length;

  console.log(
    `    ✅  Inserted ${inserted} records — PRESENT: ${presentCount} · ABSENT: ${absentCount} · LATE: ${lateCount} · FLAGGED: ${flaggedCount}\n`
  );

  // ── 8. Final Summary ─────────────────────────────────────────────────────────
  console.log("═".repeat(62));
  console.log("🎉  Seeding complete!\n");
  console.log("🔒  Triple-Lock Security Protocol Mock Data");
  console.log("─".repeat(62));
  console.log(`  Flagged records: ${flaggedCount}  (biometric signature changes)`);
  console.log("  These records have auditSelfieUrl and flaggedForReview = true");
  console.log("─".repeat(62));

  console.log("\n🔑  Login credentials  (password: Password@123)");
  console.log("─".repeat(62));
  console.log("  staff@test.com            → STAFF  (Dr. Aris)");
  console.log("─".repeat(62));
  students.forEach((s, i) =>
    console.log(
      `  student${pad(i + 1)}@test.com      → STUDENT (${s.name} · ${studentRawData[i].id})`
    )
  );
  console.log("─".repeat(62));

  console.log("\n📚  Classes created:");
  console.log(
    `  [MAD-SEM4]  Mobile App Development  — ${groupA.length} students  — BSSID: 2c:fd:a1:b3:e5:10`
  );
  console.log(
    `  [DBS-SEM4]  Database Systems         — ${groupB.length} students  — BSSID: aa:bb:cc:11:22:33`
  );
  console.log(
    `  [NSE-SEM4]  Network Security         — ${groupC.length} students  — BSSID: dd:ee:ff:44:55:66`
  );

  console.log("\n📋  Attendance (last 7 days):");
  console.log(
    `  ${inserted} records — ${presentCount} PRESENT · ${absentCount} ABSENT · ${lateCount} LATE · ${flaggedCount} FLAGGED`
  );
  console.log("═".repeat(62));

  await mongoose.disconnect();
  console.log("\n🔌  Disconnected. Done.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("\n❌  Seeding failed:", err.message || err);
  mongoose.disconnect();
  process.exit(1);
});
