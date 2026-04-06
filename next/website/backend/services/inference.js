/**
 * Inference Service
 * 
 * Wrapper to call the Python inference harness.
 * Spawns a Python process and captures the result.
 */

const { spawn } = require('child_process');
const path = require('path');

const HARNESS_PATH = path.join(__dirname, '../../../next/infer/harness.py');

/**
 * Infer metadata from a script URL.
 * 
 * @param {string} url - Script URL (e.g., "gh:user/repo/script.sh")
 * @returns {Promise<object>} Inference result
 */
async function inferUrl(url) {
  return new Promise((resolve, reject) => {
    // Spawn Python process
    const python = spawn('python3', [HARNESS_PATH, url]);
    
    let stdout = '';
    let stderr = '';
    
    python.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    python.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    python.on('close', (code) => {
      if (code === 0) {
        try {
          const result = JSON.parse(stdout);
          resolve(result);
        } catch (e) {
          reject(new Error(`Failed to parse inference result: ${e.message}`));
        }
      } else {
        reject(new Error(`Inference failed with code ${code}: ${stderr}`));
      }
    });
    
    python.on('error', (err) => {
      reject(new Error(`Failed to start inference: ${err.message}`));
    });
    
    // Timeout after 60 seconds
    setTimeout(() => {
      python.kill();
      reject(new Error('Inference timed out after 60 seconds'));
    }, 60000);
  });
}

/**
 * Run inference in background (for async processing).
 * 
 * @param {string} url - Script URL
 * @param {function} callback - Callback with result
 */
function inferUrlAsync(url, callback) {
  inferUrl(url)
    .then(result => callback(null, result))
    .catch(err => callback(err, null));
}

module.exports = {
  inferUrl,
  inferUrlAsync
};
