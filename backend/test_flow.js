const jwt = require("jsonwebtoken");
const http = require("http");

// Make sure to set JWT_SECRET identically to what server uses
const JWT_SECRET = "abb4a8c652639ded2f6e59aecd5cda21c804f98835d5ac42241437be49d63ee4af886633c1f649adbe62834f9d74634e016a34e96dd2117c2480328f9b3e3e99";
// We mock IDs. (For the test to succeed smoothly, the DB operations should not fail on User.findById. Wait! The route checks User.findById(req.user.id))
// So we need REAL object IDs from the DB, or we can just mock them if we don't care about the DB. Wait, requestAttendance does:
// const student = await User.findById(req.user.id); if (!student) return 404...
// Let's connect to the DB directly in the script to fetch a real student and a real staff!
const mongoose = require("mongoose");
const MONGO_URI = "mongodb+srv://23bcs031swetha_db_user:K86LY2cDVWD6yPdO@cluster0.k5rmhr3.mongodb.net/?appName=Cluster0";

async function run() {
  await mongoose.connect(MONGO_URI);
  
  // Get a real student
  const User = mongoose.connection.collection("users");
  const student = await User.findOne({ role: "STUDENT" });
  const staff = await User.findOne({ role: "STAFF" });

  if(!student || !staff) {
    console.log("No student or staff found in DB to test with.");
    process.exit(1);
  }

  console.log(`Found Student: ${student.email}`);
  console.log(`Found Staff: ${staff.email}`);

  // Generate tokens
  const studentToken = jwt.sign({ id: student._id, role: student.role, studentId: student.studentId }, JWT_SECRET, { expiresIn: "1h" });
  const staffToken = jwt.sign({ id: staff._id, role: staff.role }, JWT_SECRET, { expiresIn: "1h" });

  // Helper to make requests
  const request = (method, path, token, body = null) => {
    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'localhost',
        port: 5000,
        path: path,
        method: method,
        headers: {
          'Authorization': `Bearer ${token}`
        }
      };

      if (body) {
        options.headers['Content-Type'] = 'application/json';
        options.headers['Content-Length'] = Buffer.byteLength(JSON.stringify(body));
      }

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
      });

      req.on('error', reject);
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  };

  try {
    // 1. Generate QR (STAFF)
    console.log("Generating QR as Staff...");
    const qrRes = await request('GET', '/api/attendance/generate-qr?classCode=MAD-SEM4&period=1', staffToken);
    console.log("QR response:", qrRes.data);
    if (!qrRes.data.success) throw new Error("QR Generation failed");

    const qrToken = qrRes.data.token;

    // 2. Request Attendance (STUDENT)
    console.log("Requesting attendance as Student...");
    const reqRes = await request('POST', '/api/attendance/request', studentToken, { token: qrToken });
    console.log("Request response:", reqRes.data);

    if (!reqRes.data.success && reqRes.data.message !== 'Request already pending for this class') {
      throw new Error("Attendance request failed: " + reqRes.data.message);
    }

    // 3. Get Pending Requests (STAFF)
    console.log("Fetching pending requests as Staff...");
    const pendingRes = await request('GET', '/api/attendance/pending', staffToken);
    console.log("Pending response:", pendingRes.data);

    let targetRequest = null;
    if (pendingRes.data.data && pendingRes.data.data.length > 0) {
      targetRequest = pendingRes.data.data[0];
    } else {
       // if we hit 'Request already pending', the request exists, so fetch it to approve it
       const AttReq = mongoose.connection.collection("attendancerequests");
       targetRequest = await AttReq.findOne({ studentId: student._id.toString() || student.studentId });
    }

    if(targetRequest) {
      const requestId = targetRequest._id ? targetRequest._id.toString() : targetRequest.id;
      // 4. Approve Request (STAFF)
      console.log(`Approving request ${requestId} as Staff...`);
      const approveRes = await request('POST', '/api/attendance/approve', staffToken, { requestId });
      console.log("Approve response:", approveRes.data);
    } else {
      console.log("No pending requests found to approve.");
    }

    console.log("Test Completed Successfully.");
    process.exit(0);

  } catch (err) {
    console.error("Test Failed!", err);
    process.exit(1);
  }
}

run();
