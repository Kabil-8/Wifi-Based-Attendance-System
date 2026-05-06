require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("DB:", mongoose.connection.db.databaseName);
  
  const col = mongoose.connection.db.collection("users");
  
  // Find ALL users with staff@test.com
  const users = await col.find({ email: "staff@test.com" }).toArray();
  console.log("Total docs with staff@test.com:", users.length);
  users.forEach((u, i) => {
    console.log(`[${i}] _id: ${u._id} | role: ${u.role} | hash: ${u.password?.substring(0,20)}...`);
  });
  
  // Also check what DB we're actually in
  const allDbs = await mongoose.connection.db.admin().listDatabases();
  console.log("Available DBs:", allDbs.databases.map(d => d.name).join(", "));
  
  await mongoose.disconnect();
}
test().catch(console.error);
