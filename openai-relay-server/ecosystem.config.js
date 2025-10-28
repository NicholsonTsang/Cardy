// PM2 Process Manager Configuration
// For production deployment with auto-restart and monitoring

module.exports = {
  apps: [{
    name: 'openai-relay',
    script: './dist/index.js',
    
    // Instance configuration
    instances: 1, // Set to 'max' to use all CPU cores
    exec_mode: 'cluster', // Use cluster mode for multi-instance
    
    // Environment variables
    env: {
      NODE_ENV: 'production',
      PORT: 8080
    },
    
    // Restart policies
    autorestart: true,
    watch: false, // Set to true to watch for file changes
    max_memory_restart: '500M', // Restart if memory exceeds 500MB
    
    // Logging
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Advanced features
    min_uptime: '10s', // Minimum uptime before considered stable
    max_restarts: 10, // Max restarts within 1 minute before giving up
    restart_delay: 4000, // Delay between restarts (ms)
    
    // Graceful shutdown
    kill_timeout: 5000, // Time to wait for graceful shutdown before SIGKILL
    wait_ready: true, // Wait for app to be ready before considering it online
    listen_timeout: 10000 // Max time to wait for listen event
  }]
};

