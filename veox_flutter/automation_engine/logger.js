const log = (level, message, data = {}) => {
    process.stdout.write(JSON.stringify({
        type: 'log',
        level,
        message,
        ...data,
        timestamp: Date.now()
    }) + '\n');
};

const sendResponse = (id, status, result = null, error = null) => {
    process.stdout.write(JSON.stringify({ id, status, result, error }) + '\n');
};

module.exports = { log, sendResponse };
