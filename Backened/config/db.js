const mongoose = require('mongoose')
const dns = require('dns');

dns.setServers(['10.111.229.107', '1.1.1.1', '8.8.8.8']);

const connectDB = async () => {
  try {
    const connString = process.env.MONGO_URI;
    if (!connString) {
      console.error('❌ DATABASE CONFIG ERROR: .env file mein MONGO_URI missing hai!');
      process.exit(1);
    }

    console.log('⏳ Connecting to MongoDB cluster (Standard Protocol)...');

    const conn = await mongoose.connect(connString, {
      serverSelectionTimeoutMS: 15000 
    });

    console.log('====================================================');
    console.log('🎯 MONGO CLUSTER ONLINE: Connected to => ' + conn.connection.host);
    console.log('====================================================');
  } catch (error) {
    console.error('====================================================');
    console.error('💥 MONGO CONNECTION CRASHED!');
    console.error('DETAILS => ' + error.message);
    console.error('====================================================');
    process.exit(1);
  }
};

module.exports = connectDB;
