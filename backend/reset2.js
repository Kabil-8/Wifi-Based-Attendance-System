require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const col = mongoose.connection.db.collection("users");
  
  // Reset staff to simple password without special chars
  const hash1 = await bcrypt.hash("Staff2024", 10);
  await col.updateOne({ email: "staff@test.com" }, { $set: { password: hash1, isActive: true } });
  console.log("staff@test.com password reset to: Staff2024");
  console.log("verify:", await bcrypt.compare("Staff2024", hash1));
  
  // Reset admin too
  const hash2 = await bcrypt.hash("Admin2024", 10);
  await col.updateOne({ email: "admin@test.com" }, { $set: { password: hash2, isActive: true } });
  console.log("admin@test.com password reset to: Admin2024");
  
  // Check student01
  const s = await col.findOne({ email: "student01@test.com" });
  console.log("student01 hash:", s?.password?.substring(0,20));
  
  await mongoose.disconnect();
}
run().catch(console.error);
