require("dotenv").config();
const mongoose = require("mongoose");
const User = require("./src/models/User"); // Ensure path matches your structure

async function fixPasswords() {
  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("✅ Connected to MongoDB.");

    // Find users with plain text passwords (bcrypt hashes start with $2a$ or $2b$)
    const users = await User.find({ password: { $not: /^\$2[ab]\$/ } });

    if (users.length === 0) {
      console.log("🎉 No plaintext passwords found. All passwords are encrypted.");
    } else {
      console.log(`⚠️ Found ${users.length} users with plaintext passwords. Fixing...`);
      for (const user of users) {
        console.log(`Fixing password for: ${user.email}`);

        // Mongoose pre('save') hook will automatically hash the password
        // Since we fetched it, we just need to mark it as modified and save it
        user.markModified("password");
        await user.save();

        console.log(`✅ Fixed: ${user.email}`);
      }
      console.log("🎉 All passwords fixed!");
    }

  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from MongoDB.");
  }
}

fixPasswords();
