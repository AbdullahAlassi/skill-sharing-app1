const cron = require('node-cron');
const SchedulerService = require('../services/schedulerService');

// Run every hour
cron.schedule('0 * * * *', async () => {
  console.log('Running event reminders check...');
  await SchedulerService.sendEventReminders();
});

// Run daily at midnight
cron.schedule('0 0 * * *', async () => {
  console.log('Running notification cleanup...');
  await SchedulerService.cleanupOldNotifications();
});

module.exports = cron; 