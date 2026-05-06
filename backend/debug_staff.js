require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

async function check() {
  await mongoose.connect(process.env.MONGO_URI);
  const col = mongoose.connection.db.collection("users");
  const user = await col.findOne({ email: "staff@test.com" });
  console.log("Found:", !!user);
  console.log("Role:", user?.role);
  console.log("isActive:", user?.isActive);
  console.log("Hash prefix:", user?.password?.substring(0, 7));
  console.log("Hash length:", user?.password?.length);
  const result = await bcrypt.compare("Staff@123", user.password);
  console.log("bcrypt compare Staff@123:", result);
  const result2 = await bcrypt.compare("staff123", user.password);
  console.log("bcrypt compare staff123:", result2);
  await mongoose.disconnect();
}
check().catch(console.error);
