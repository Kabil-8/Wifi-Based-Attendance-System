const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, "../.env") });
const User = require("./models/User");

async function fix() {
  try {
    console.log("Connecting...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected.");
    
    const users = await User.find({ email: /test\.com$/ });
    console.log(`Found ${users.length} users.`);
    
    for (const user of users) {
      user.password = "Password@123";
      await user.save();
      console.log(`Updated ${user.email}`);
    }
    
    console.log("Done.");
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fix();
