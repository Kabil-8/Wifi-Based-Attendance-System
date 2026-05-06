require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  const col = mongoose.connection.db.collection("users");
  const user = await col.findOne({ email: "staff@test.com" });
  
  // Test common passwords
  const passwords = ["Staff@123", "staff123", "Staff123", "password", "123456", "staff@123", "Password@123"];
  for (const pwd of passwords) {
    const ok = await bcrypt.compare(pwd, user.password);
    if (ok) console.log("MATCH:", pwd);
    else console.log("no match:", pwd);
  }
  await mongoose.disconnect();
}
test().catch(console.error);
