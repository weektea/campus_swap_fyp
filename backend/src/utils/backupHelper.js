import { exec } from 'child_process';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { Op } from 'sequelize';
import util from 'util';
import sequelize from '../config/database.js';
import { BackupLog } from '../models/index.js';

const execAsync = util.promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define backups directory in the backend root
const BACKUPS_DIR = path.join(__dirname, '..', '..', 'backups');

/**
 * Resolves paths to PostgreSQL command line tools (pg_dump or psql).
 * Supports auto-discovery on Windows for standard installation directories.
 */
export const getPgToolPath = (toolName) => {
    // 1. Check custom path in env variables first
    const envPathVar = toolName === 'pg_dump' ? process.env.PG_DUMP_PATH : process.env.PSQL_PATH;
    if (envPathVar) return envPathVar;

    // 2. On Windows, attempt to auto-discover in common paths (e.g. C:\Program Files\PostgreSQL\<version>\bin)
    if (process.platform === 'win32') {
        const standardParent = 'C:\\Program Files\\PostgreSQL';
        if (fs.existsSync(standardParent)) {
            try {
                const versions = fs.readdirSync(standardParent);
                // Sort versions descending (e.g. 16, 15, 14...) to use the latest version
                versions.sort((a, b) => parseFloat(b) - parseFloat(a));
                for (const ver of versions) {
                    const toolExe = path.join(standardParent, ver, 'bin', `${toolName}.exe`);
                    if (fs.existsSync(toolExe)) {
                        return toolExe;
                    }
                }
            } catch (err) {
                console.error('Failed to search PostgreSQL directory:', err);
            }
        }
    }

    // 3. Fallback to default command name in system PATH
    return toolName;
};

/**
 * Helper to generate precise date format YYYY-MM-DD_HH-mm-ss
 */
const getFormattedTimestamp = () => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day}_${hours}-${minutes}-${seconds}`;
};

/**
 * Checks if the PostgreSQL docker container is running.
 */
const isDockerRunning = async () => {
    try {
        const { stdout } = await execAsync('docker ps -q -f name=campus_swap_db');
        return stdout.trim().length > 0;
    } catch {
        return false;
    }
};

/**
 * Triggers a real pg_dump command to back up the database schema and data.
 * Supports running inside Docker or host system.
 * @param {string} type - 'Manual' or 'Auto'
 */
export const executeBackup = async (type = 'Manual') => {
    // Check directory existence and create if missing (recusively)
    if (!fs.existsSync(BACKUPS_DIR)) {
        fs.mkdirSync(BACKUPS_DIR, { recursive: true });
    }

    const timestamp = getFormattedTimestamp();
    const filename = `backup_${timestamp}.sql`;
    const backupPath = path.join(BACKUPS_DIR, filename);

    const dbHost = process.env.DB_HOST || 'localhost';
    const dbPort = process.env.DB_PORT || 5432;
    const dbUser = process.env.DB_USER || 'postgres';
    const dbPass = process.env.DB_PASSWORD || process.env.DB_PASS || 'postgres';
    const dbName = process.env.DB_NAME || 'campus_swap';

    const useDocker = await isDockerRunning();
    const env = { ...process.env, PGPASSWORD: dbPass };

    if (useDocker) {
        console.log('Docker database container detected. Backing up via Docker...');
        const tempContainerFile = `/var/lib/postgresql/data/temp_backup_${timestamp}.sql`;

        // 1. Run pg_dump inside container, setting PGPASSWORD securely
        const dumpCmd = `docker exec -i -e PGPASSWORD campus_swap_db pg_dump -h localhost -p 5432 -U ${dbUser} -d ${dbName} -F p -f "${tempContainerFile}"`;
        await execAsync(dumpCmd, { env });

        // 2. Copy the sql file back to the host
        const cpCmd = `docker cp campus_swap_db:${tempContainerFile} "${backupPath}"`;
        await execAsync(cpCmd);

        // 3. Clean up container file
        const rmCmd = `docker exec -i campus_swap_db rm "${tempContainerFile}"`;
        await execAsync(rmCmd);
    } else {
        console.log('Native database environment assumed. Backing up via host native tool...');
        const pgDumpPath = getPgToolPath('pg_dump');
        
        // Run pg_dump natively, setting PGPASSWORD securely
        const dumpCmd = `"${pgDumpPath}" -h ${dbHost} -p ${dbPort} -U ${dbUser} -d ${dbName} -F p -f "${backupPath}"`;
        await execAsync(dumpCmd, { env });
    }

    // Check size and record logs
    const stats = fs.statSync(backupPath);
    const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2) + ' MB';

    const log = await BackupLog.create({
        type,
        size: sizeInMB,
        status: 'Success',
        file_path: backupPath
    });

    return log;
};

/**
 * Restores the PostgreSQL database structure and data from a backup log.
 * Supports running inside Docker or host system.
 * @param {string} backupId - UUID of the BackupLog
 */
export const executeRestore = async (backupId) => {
    const backup = await BackupLog.findByPk(backupId);
    if (!backup) {
        throw new Error('Backup point not found in database.');
    }
    if (!backup.file_path || !fs.existsSync(backup.file_path)) {
        throw new Error('Backup file does not exist on server disk.');
    }

    const dbHost = process.env.DB_HOST || 'localhost';
    const dbPort = process.env.DB_PORT || 5432;
    const dbUser = process.env.DB_USER || 'postgres';
    const dbPass = process.env.DB_PASSWORD || process.env.DB_PASS || 'postgres';
    const dbName = process.env.DB_NAME || 'campus_swap';

    // 1. Wipe the current active database schema
    console.log('Wiping active database schema to prepare for restore...');
    await sequelize.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');

    const useDocker = await isDockerRunning();
    const env = { ...process.env, PGPASSWORD: dbPass };

    try {
        if (useDocker) {
            console.log('Docker database container detected. Restoring via Docker...');
            const tempContainerFile = `/var/lib/postgresql/data/temp_restore_${backupId}.sql`;

            // 1. Copy host backup file to container
            const cpCmd = `docker cp "${backup.file_path}" campus_swap_db:${tempContainerFile}`;
            await execAsync(cpCmd);

            // 2. Execute psql import inside container
            const restoreCmd = `docker exec -i -e PGPASSWORD campus_swap_db psql -h localhost -p 5432 -U ${dbUser} -d ${dbName} -f "${tempContainerFile}"`;
            await execAsync(restoreCmd, { env });

            // 3. Clean up container temp file
            const rmCmd = `docker exec -i campus_swap_db rm "${tempContainerFile}"`;
            await execAsync(rmCmd);
        } else {
            console.log('Native database environment assumed. Restoring via native tool...');
            const psqlPath = getPgToolPath('psql');
            const restoreCmd = `"${psqlPath}" -h ${dbHost} -p ${dbPort} -U ${dbUser} -d ${dbName} -f "${backup.file_path}"`;
            await execAsync(restoreCmd, { env });
        }
        
        return { success: true, message: `Database successfully restored to backup point ${backup.id}.` };
    } catch (restoreErr) {
        console.error('Database restore failed. Initiating emergency recovery sync...', restoreErr);
        try {
            await sequelize.sync();
            console.log('Emergency schema sync succeeded (database tables recreated but empty).');
        } catch (syncErr) {
            console.error('Emergency schema sync failed:', syncErr);
        }
        throw new Error(`Restore execution failed: ${restoreErr.message}`);
    }
};

/**
 * Prunes backup files and database logs older than 7 days.
 */
export const pruneOldBackups = async () => {
    try {
        const thresholdDate = new Date();
        thresholdDate.setDate(thresholdDate.getDate() - 7);

        const oldLogs = await BackupLog.findAll({
            where: {
                createdAt: {
                    [Op.lt]: thresholdDate
                }
            }
        });

        console.log(`Pruning ${oldLogs.length} backup logs older than 7 days...`);
        for (const log of oldLogs) {
            if (log.file_path && fs.existsSync(log.file_path)) {
                try {
                    fs.unlinkSync(log.file_path);
                    console.log(`Deleted backup file: ${log.file_path}`);
                } catch (fileErr) {
                    console.error(`Failed to delete backup file ${log.file_path}:`, fileErr);
                }
            }
            await log.destroy();
        }
    } catch (e) {
        console.error('Failed to prune old backups:', e);
    }
};
