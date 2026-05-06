const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });

const User = require("./models/User");

async function checkUsers() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");
    const users = await User.find({}, "email role name");
    console.log("Users in DB:");
    users.forEach(u => console.log(`- ${u.email} (${u.role}) - ${u.name}`));
    await mongoose.disconnect();
  } catch (error) {
    console.error("Error:", error);
  }
}

checkUsers();
