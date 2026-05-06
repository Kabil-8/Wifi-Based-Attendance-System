require("dotenv").config();
const m = require("mongoose");
const b = require("bcryptjs");

async function run() {
  await m.connect(process.env.MONGO_URI);
  const col = m.connection.db.collection("users");
  
  // Set to "staff123" - simplest possible no capitals no special chars
  const hash = await b.hash("staff123", 10);
  await col.updateOne({ email: "staff@test.com" }, { $set: { password: hash, isActive: true } });
  
  const verify = await b.compare("staff123", hash);
  console.log("Password set to 'staff123', verify:", verify);
  
  // Show current staff user
  const u = await col.findOne({ email: "staff@test.com" }, { projection: { email:1, role:1, isActive:1 } });
  console.log("Staff user:", JSON.stringify(u));
  
  await m.disconnect();
}
run().catch(console.error);
