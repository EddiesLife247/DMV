-- eb_dmv – manual SQL (auto-created on first server start, but kept here for reference)
CREATE TABLE IF NOT EXISTS `eb_dmv_licenses` (
    `citizenid`           VARCHAR(50)  NOT NULL,
    `licensecar`          TINYINT(1)   NOT NULL DEFAULT 0,
    `licensebushgv`       TINYINT(1)   NOT NULL DEFAULT 0,
    `licenseplane`        TINYINT(1)   NOT NULL DEFAULT 0,
    `licensehelicopter`   TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Check who has what licenses
SELECT citizenid,
       IF(licensecar=1,'✅','❌') AS car,
       IF(licensebushgv=1,'✅','❌') AS bus_hgv,
       IF(licenseplane=1,'✅','❌') AS plane,
       IF(licensehelicopter=1,'✅','❌') AS helicopter
FROM eb_dmv_licenses;
